require_relative '../models/pa_pc_case_runs'
require_relative '../models/pa_pc_case_info'
require_relative '../models/pa_pc_case_pdfs_on_aws'
require_relative '../models/pa_pc_case_relations_info_pdf'
require_relative '../models/pa_pc_case_party'
require_relative '../models/pa_pc_case_activities'

class PaPhiladelphiaCourtKeeper
  COURT_ID    = 70
  SOURCE_TYPE = 'info'.freeze

  def initialize
    @count  = 0
    @run_id = run.run_id
    @s3     = AwsS3.new(bucket_key = :us_court)
  end

  attr_accessor :count
  attr_reader :run_id

  def status
    run.status
  end

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  def case_exist?(id)
    !find_case_info(id).nil?
  end

  def get_pdfs_md5_hash(id)
    find_pdfs_on_aws(id)&.md5_hash
  end

  def get_active_cases
    ids = PaPcCaseInfo.where(deleted: 0, status_as_of_date: nil).pluck(:case_id)
                      .or(PaPcCaseInfo.where(deleted: 0).where.not(status_as_of_date: 'Closed').pluck(:case_id))
    PaPcCasePdfsOnAws.where(deleted: 0, case_id: ids).select(:case_id, :court_summary, :source_link)
                     .as_json(except: :id).map(&:symbolize_keys)
  end

  def save_start_data(data, pdf, pdf_2)
    @case_id  = data[:case_id]
    info      = data.delete(:info)
    base_info = { run_id: run_id, touched_run_id: run_id, court_id: COURT_ID, case_id: @case_id }
    start_save_info(info.merge(base_info)) if info
    md5      = MD5Hash.new(columns: %i[case_id, pdf, pdf_2, link_pdf])
    md5_hash = md5.generate({ case_id: @case_id, pdf: pdf, pdf_2: pdf_2, link_pdf: data[:source_link] })
    pdfs_db  = find_pdfs_on_aws(data[:case_id])
    return if pdfs_db&.md5_hash == md5_hash

    aws_link   = save_aws(pdf)
    aws_link_2 = save_aws(pdf_2)
    data.merge!({ aws_link: aws_link, aws_link_2: aws_link_2, md5_hash: md5_hash })
    data[:source_type] = SOURCE_TYPE
    data[:court_id]    = COURT_ID
    save_pdfs_on_aws(data, pdfs_db)
  end

  def update_case_info(case_info_finish)
    case_id      = case_info_finish.delete(:case_id)
    current_case = find_case_info(case_id)
    @base_info   = current_case.attributes.to_a.values_at(2..3, 13).to_h.transform_keys(&:to_sym)
    @base_info[:run_id] = run_id
    start_data = { case_name: current_case.case_name, case_filed_date: current_case.case_filed_date }
    full_data  = start_data.merge(case_info_finish, @base_info)
    md5        = MD5Hash.new(table: :info)
    @md5_hash  = md5.generate(full_data)
    full_data[:md5_hash]       = @md5_hash
    full_data[:touched_run_id] = run_id
    if current_case.md5_hash != @md5_hash
      current_case.update({ deleted: 1 })
      PaPcCaseInfo.store(full_data)
    else
      current_case.update(full_data)
    end
    @count += 1
  end

  def save_case_relations_info_pdf
    pdf_on_aws_md5 = find_pdfs_on_aws(@base_info[:case_id]).md5_hash
    data           = { case_info_md5: @md5_hash, case_pdf_on_aws_md5: pdf_on_aws_md5 }
    PaPcRelationsInfoPdf.store(data)
  end

  def save_case_party(case_parties)
    case_parties.each do |party|
      party.merge!(@base_info)
      md5              = MD5Hash.new(table: :party)
      party[:md5_hash] = md5.generate(party)
      PaPcCaseParty.store(party)
    end
  end

  def save_activities(activities)
    activities.each do |activity|
      activity.merge!(@base_info)
      columns             = %i[court_id case_id activity_date activity_decs activity_type]
      md5                 = MD5Hash.new(columns: columns)
      activity[:md5_hash] = md5.generate(activity)
      PaPcCaseActivities.store(activity)
    end
  end

  private

  def find_case_info(id)
    PaPcCaseInfo.find_by(case_id: id, deleted: 0)
  end

  def find_pdfs_on_aws(id)
    PaPcCasePdfsOnAws.find_by(case_id: id, deleted: 0)
  end

  def start_save_info(data)
    PaPcCaseInfo.store(data.compact) unless find_case_info(@case_id)
  end

  def save_aws(pdf)
    return if pdf.nil?

    md5 = MD5Hash.new(columns: %i[pdf])
    md5.generate({ pdf: pdf })
    md5_hash = md5.hash
    case_id  = @case_id.gsub(' ', '_')
    key      = "us_courts_#{COURT_ID}_#{case_id}_#{md5_hash}.pdf"
    @s3.put_file(pdf, key, metadata = {})
  end

  def save_pdfs_on_aws(data, pdfs_on_aws)
    pdfs_on_aws.update({ deleted: 1 }) if pdfs_on_aws && pdfs_on_aws.md5_hash != data[:md5_hash]
    PaPcCasePdfsOnAws.store(data)
  end

  def safe_connection(models, try=10)
    yield if block_given?
  rescue *connection_error_classes => e
    begin
      try -= 1
      raise '#438 | Connection could not be established | Keeper' if try.zero?

      Hamster.logger.error(e)
      Hamster.report(to: 'U0219D1D3KN', message: "##{Hamster.project_number} | #{e}", use: :slack)
      sleep 100
      [models].flatten.each { |i| i.connection.reconnect! }
    rescue *connection_error_classes => e
      retry
    end
    retry
  ensure
    models.connection.close
  end

  def connection_error_classes
    [ActiveRecord::ConnectionNotEstablished,
     Mysql2::Error::ConnectionError,
     ActiveRecord::StatementInvalid,
     ActiveRecord::LockWaitTimeout]
  end

  def run
    RunId.new(PaPcCaseRuns)
  end
end
