require_relative '../models/wisc_case_runs'
require_relative '../models/wisc_case_info'
require_relative '../models/wisc_case_party'
require_relative '../models/wisc_case_activities'
require_relative '../models/wisc_case_consolidations'
require_relative '../models/wisc_case_additional_info'
require_relative '../models/wisc_case_pdfs_on_aws'
require_relative '../models/wisc_case_relations_activity_pdf'

class WiscCourtsKeeper
  def initialize
    @count     = 0
    @updated   = 0
    @count_aws = 0
    @run_id    = run.run_id
  end

  attr_accessor :id
  attr_reader :run_id, :count, :updated, :count_aws

  def get_not_pdf_link
    WiscCaseInfo.where(deleted: 0, run_id: run_id).pluck(:court_id, :case_id, :md5_hash, :data_source_url)
  end

  def save_relation_info_pdf(case_info_md5, md5_hash)
    data = { case_info_md5: case_info_md5, case_pdf_on_aws_md5: md5_hash }
    WiscCaseRelationsInfoPdf.store(data)
  end

  def case_exists?(case_id)
    !WiscCaseInfo.find_by(deleted: 0, case_id: case_id).nil?
  end

  def get_open_case
    WiscCaseInfo.where(deleted: 0).where.not(status_as_of_date: 'CL').pluck(:case_id)
  end

  def save_case(case_details)
    case_party     = case_details.delete(:case_party)
    consolidations = case_details.delete(:cons_details)
    additional     = case_details.delete(:additional)
    @id            = case_details.to_a[0, 2].to_h
    save_info(case_details)
    save_party(case_party)
    save_consolidations(consolidations) unless consolidations.empty?
    save_additional(additional)
  end

  def check_date_info
    unless @filed_date.nil? || @filed_date.empty?
      wisc_case_info = WiscCaseInfo.find_by(deleted: 0, case_id: @id[:case_id])
      wisc_case_info.update(case_filed_date: @filed_date) if wisc_case_info[:case_filed_date].nil?
    end
  end

  def save_activities(activities)
    md5_hashes  = WiscCaseActivities.where(case_id: @id[:case_id]).pluck(:md5_hash)
    @filed_date = activities[0][:activity_date]
    activities.each do |activity|
      link     = "https://wscca.wicourts.gov/appealHistory.xsl?caseNo=#{@id[:case_id]}"
      activity = activity.merge(@id)
      md5      = MD5Hash.new(columns: activity.keys)
      md5.generate(activity)
      activity[:md5_hash] = md5.hash
      next if md5_hashes.include?(activity[:md5_hash])

      activity[:run_id] = @run_id
      activity = activity.merge({ data_source_url: link })
      WiscCaseActivities.store(activity.compact)
    end
  end

  def save_consolidations(consolidations)
    consolidations.each do |detail|
      link   = "https://wscca.wicourts.gov/caseDetails.do?caseNo=#{@id[:case_id]}"
      detail = detail.merge(@id)
      md5    = MD5Hash.new(columns: detail.keys)
      md5.generate(detail)
      detail[:md5_hash] = md5.hash
      detail = detail.merge({ data_source_url: link })
      WiscCaseConsolidations.store(detail)
    end
  end

  def save_additional(additional_details)
    additional_details.each do |detail|
      link   = "https://wscca.wicourts.gov/caseDetails.do?caseNo=#{@id[:case_id]}"
      keys   = %i[court_id case_id lower_court_name lower_case_id lower_judge_name lower_link disposition]
      md5    = MD5Hash.new(columns: keys)
      detail = detail.merge(@id).merge({ data_source_url: link })
      md5.generate(detail)
      detail[:md5_hash] = md5.hash
      WiscCaseAdditionalInfo.store(detail)
    end
  end

  def get_file_activities
    links_db = WiscCasePdfsOnAws.where(run_id: @run_id).pluck(:source_link) | [nil, '']
    WiscCaseActivities.where(run_id: @run_id).where.not(file: links_db).map do |i|
      { file: i.file, court_id: i.court_id, case_id: i.case_id, md5_hash: i.md5_hash }
    end
  end

  def save_pdfs_aws_info(pdfs_aws, activity_hash, model=:activity)
    md5 = MD5Hash.new(table: :pdfs_on_aws)
    md5.generate(pdfs_aws)
    pdfs_aws[:md5_hash] = md5.hash
    pdfs_aws[:run_id]   = @run_id
    WiscCasePdfsOnAws.store(pdfs_aws, activity_hash, model)
    @count_aws += 1
  end

  def save_relations_activity_pdf(activities_md5, aws_md5)
    WiscCaseRelationsActivityPdf.store(case_activities_md5: activities_md5, case_pdf_on_aws_md5: aws_md5)
  end

  def finish
    run.finish
  end

  def status=(new_status)
    run.status = new_status
  end

  private

  def save_info(case_details)
    md5 = MD5Hash.new(table: :info)
    md5.generate(case_details.to_a[0, 6].to_h)
    case_details[:md5_hash] = md5.hash
    case_details[:run_id] = run_id
    info = WiscCaseInfo.find_by(case_id: case_details[:case_id], deleted: 0)
    case_details = case_details.compact
    if info.nil?
      WiscCaseInfo.store(case_details)
      @count += 1
    elsif info.status_as_of_date != 'CL' && case_details[:status_as_of_date] == 'CL'
      info.update(deleted: 1)
      WiscCaseInfo.store(case_details)
      @updated += 1
    else
      @updated += 1
    end
  end

  def save_party(parties)
    md5_hashes = WiscCaseParty.where(case_id: @id[:case_id]).pluck(&:md5_hash)
    parties.each do |party|
      md5   = MD5Hash.new(table: :party)
      party = party.merge(@id)
      md5.generate(party)
      party[:md5_hash] = md5.hash
      next if md5_hashes.include?(party[:md5_hash])

      link  = "https://wscca.wicourts.gov/caseDetails.do?caseNo=#{@id[:case_id]}"
      party = party.merge({ data_source_url: link })
      WiscCaseParty.store(party.compact)
    end
  end

  def run
    RunId.new(WiscCaseRuns)
  end
end
