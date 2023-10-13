require_relative '../models/pa_sc_case_runs'
require_relative '../models/pa_sc_case_info'
require_relative '../models/pa_sc_case_pdfs_on_aws'
require_relative '../models/pa_sc_case_relations_info_pdf'
require_relative '../models/pa_sc_case_additional_info'
require_relative '../models/pa_sc_case_party'
require_relative '../models/pa_sc_case_consolidations'
require_relative '../models/pa_sc_case_activities'

class PaScCaseKeeper
  COURT_ID    = 339
  SOURCE_TYPE = 'info'.freeze

  def initialize
    @run_id   = run.run_id
    @run_keys = { run_id: @run_id, touched_run_id: @run_id }
  end

  attr_reader :run_id

  def not_saved_cases(court_cases)
    case_ids       = court_cases.map { |i| i[:case_id] }
    court_cases_db = PaScCaseInfo.where(case_id: case_ids, deleted: 0).pluck(:case_id)
    court_cases.reject { |i| court_cases_db.include?(i[:case_id]) }
  end

  def get_active_cases
    PaScCaseInfo.where(deleted: 0).where.not(status_as_of_date: 'Closed').pluck(:case_id, :data_source_url).map do |i|
      { court_id: COURT_ID, case_id: i.at(0), source_type: SOURCE_TYPE, source_link: i.at(1) }
    end
  end

  def save_start_data(data, pdf)
    data[:court_id]    = COURT_ID
    data[:source_type] = SOURCE_TYPE
    @case_id           = data[:case_id]
    info               = data.delete(:info)
    if info #for active case not save start info table
      info.merge!(@run_keys)
      start_save_info(info)
    end
    save_pdfs_on_aws(data, pdf)
  end

  def update_info(case_info)
    case_id        = case_info.delete(:case_id)
    current_case   = existing_case(PaScCaseInfo, case_id)
    url            = current_case.data_source_url
    @additional    = case_info.delete(:additional_info)
    lower_case_id  = @additional.map { |i| i[:lower_case_id] }.join('; ')
    lower_court_id = @additional.map { |i| i[:lower_court_id] }.join('; ')
    @base          = { court_id: current_case.court_id, case_id: case_id, data_source_url: url }
    start_data     = { case_name: current_case.case_name, case_filed_date: current_case.case_filed_date,
                      lower_case_id: lower_case_id, lower_court_id: lower_court_id }
    full_data      = start_data.merge(case_info, @base)
    full_data      = replace_empty_with_nil(full_data)
    md5            = MD5Hash.new(table: :info)
    md5.generate(full_data)
    full_data.merge!(@run_keys)
    @md5_info            = md5.hash
    full_data[:md5_hash] = @md5_info

    if current_case.md5_hash.nil?
      current_case.update(full_data.compact)
    elsif current_case.md5_hash != @md5_info
      current_case.update({ deleted: 1 })
      PaScCaseInfo.store(full_data.compact)
    else
      current_case.update(touched_run_id: run_id)
    end
  end

  def save_relations_info_pdf
    md5_aws = existing_case(PaScCasePdfsOnAws, @base[:case_id]).md5_hash
    data    = { case_info_md5: @md5_info, case_pdf_on_aws_md5: md5_aws }
    PaScCaseRelationsInfoPdf.store(data)
  end

  def save_additional_info
    @additional.each do |data|
      data.delete(:lower_court_id)
      data.merge!(@base)
      columns = %i[court_id case_id lower_court_name lower_case_id lower_judge_name lower_link disposition]
      data    = replace_empty_with_nil(data)
      md5     = MD5Hash.new(columns: columns)
      md5.generate(data)
      data[:md5_hash] = md5.hash
      save_with_touch(PaScCaseAdditionalInfo, data)
    end
    delete_not_touched(PaScCaseAdditionalInfo)
  end

  def save_party(parties)
    parties.each do |party|
      party.merge!(@base, @run_keys)
      party = replace_empty_with_nil(party)
      keys  = %i[court_id case_id party_name party_type is_lawyer party_address]
      md5   = MD5Hash.new(columns: keys)
      md5.generate(party)
      party[:md5_hash] = md5.hash
      save_with_touch(PaScCaseParty, party)
    end
    delete_not_touched(PaScCaseParty)
  end

  def save_consolidations(ids)
    ids.each do |i|
      data = @base.merge({ consolidated_case_id: i })
      md5  = MD5Hash.new(columns: %i[court_id case_id consolidated_case_id])
      md5.generate(data)
      data[:md5_hash] = md5.hash
      PaScCaseConsolidations.store(data)
    end
  end

  def save_activities(activities)
    activities.each do |activity|
      activity.merge!(@base, @run_keys)
      columns = %i[court_id case_id activity_date activity_desc activity_type]
      md5     = MD5Hash.new(columns: columns)
      md5.generate(activity)
      activity[:md5_hash] = md5.hash
      save_with_touch(PaScCaseActivities, activity)
    end
    delete_not_touched(PaScCaseActivities)
  end

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  private

  def save_with_touch(model, data)
    model.find_by(md5_hash: data[:md5_hash])&.update(touched_run_id: run_id) || model.store(data)
  end

  def delete_not_touched(model)
    model.where(case_id: @base[:case_id], deleted: 0).where.not(touched_run_id: run_id).each { |i| i.update(deleted: 1) }
  end

  def existing_case(model, id)
    model.find_by(case_id: id, deleted: 0)
  end

  def replace_empty_with_nil(data)
    data.transform_values { |i| i.blank? ? nil : i }
  end

  def start_save_info(data)
    data[:court_id] = COURT_ID
    data[:case_id]  = @case_id
    PaScCaseInfo.store(data.compact) unless existing_case(PaScCaseInfo, @case_id)
  end

  def save_aws(pdf)
    return if pdf.nil?

    s3        = AwsS3.new(bucket_key = :us_court)
    case_id   = @case_id.gsub(' ', '_')
    key_start = "pa_sc_case_#{COURT_ID}_#{case_id}_"
    file_name = "#{Time.now.to_i.to_s}.pdf"
    key       = key_start + file_name
    s3.put_file(pdf, key, metadata = {})
  end

  def save_pdfs_on_aws(data, pdf)
    md5             = MD5Hash.new(columns: %i[pdf])
    data[:md5_hash] = md5.generate({ pdf: pdf })
    pdf_db          = existing_case(PaScCasePdfsOnAws, data[:case_id])
    return pdf_db.update(touched_run_id: run_id) if pdf_db&.md5_hash == data[:md5_hash]

    data[:aws_link] = save_aws(pdf)
    data.merge!(@run_keys)
    pdf_db.update(deleted: 1) if pdf_db && pdf_db.md5_hash != data[:md5_hash]
    PaScCasePdfsOnAws.store(data.compact) if pdf_db&.md5_hash != data[:md5_hash]
  end

  def run
    RunId.new(PaScCaseRuns)
  end
end
