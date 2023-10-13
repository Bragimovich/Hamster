# frozen_string_literal: true
require_relative '../models/nh_sc_case_info'
require_relative '../models/nh_sc_case_party'
require_relative '../models/nh_sc_case_info_runs'
require_relative '../models/nh_sc_case_activities'
require_relative '../models/nh_sc_case_pdfs_on_aws'
require_relative '../models/nh_sc_case_additional_info'
require_relative '../models/nh_sc_case_relations_activity_pdf'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NhScCaseInfoRuns)
    @run_id = @run_object.run_id
  end

  def insert_info(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    NhScCaseInfo.insert_all(list_of_hashes)
  end

  def insert_additional_info(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    NhScCaseAdditionalInfo.insert_all(list_of_hashes)
  end

  def update_case_info_accepted(list_of_hashes)
    return if list_of_hashes.empty?
    return if @run_id == 1
    list_of_hashes.each do |hash|
      NhScCaseInfo.where(case_id:hash[:case_id]).update(case_name:hash[:case_name])
    end
  end

  def insert_activities(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    NhScCaseActivities.insert_all(list_of_hashes)
  end

  def insert_party(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map {|hash| add_run_id(hash) }
    NhScCaseParty.insert_all(list_of_hashes)
  end

  def insert_pdf_on_aws(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    NhScCasePdfsOnAws.insert_all(list_of_hashes)
  end

  def insert_relations_activity_pdf(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    NhScCaseRelationsActivityPdf.insert_all(list_of_hashes)
  end

  def update_case_accepted(data_hash)
    return if data_hash.empty?
    return if @run_id == 1
    NhScCaseInfo.where(case_id:data_hash[:case_id]).where(md5_hash:data_hash[:md5_info]).update_all("deleted=0, touched_run_id=#{run_id}")
    NhScCaseInfo.where(case_id:data_hash[:case_id]).where.not(md5_hash:data_hash[:md5_info]).update_all(deleted:1)

    NhScCaseAdditionalInfo.where(case_id:data_hash[:case_id]).where(md5_hash:data_hash[:md5_add_info]).update_all("deleted=0, touched_run_id=#{run_id}")
    NhScCaseAdditionalInfo.where(case_id:data_hash[:case_id]).where.not(md5_hash:data_hash[:md5_add_info]).update_all(deleted:1)
  end

  def update_case_opinion(md5_hash, case_id)
    return if md5_hash.empty?
    NhScCaseInfo.where(case_id:case_id).where(md5_hash:md5_hash[:md5_info]).update_all("deleted=0, touched_run_id=#{run_id}")
    NhScCaseInfo.where(case_id:case_id).where.not(md5_hash:md5_hash[:md5_info]).update_all(deleted:1)

    NhScCaseActivities.where(case_id:case_id).where(md5_hash:md5_hash[:md5_activity]).update_all("deleted=0, touched_run_id=#{run_id}")
    NhScCaseActivities.where(case_id:case_id).where.not(md5_hash:md5_hash[:md5_activity]).update_all(deleted:1)

    NhScCaseParty.where(case_id:case_id).where(md5_hash:md5_hash[:md5_party]).update_all("deleted=0, touched_run_id=#{run_id}")

    NhScCasePdfsOnAws.where(case_id:case_id).where(md5_hash:md5_hash[:md5_pdf_on_aws]).update_all("deleted=0, touched_run_id=#{run_id}")
    NhScCasePdfsOnAws.where(case_id:case_id).where.not(md5_hash:md5_hash[:md5_pdf_on_aws]).update_all(deleted:1)
  end

  def add_run_id(hash)
    hash[:run_id] = @run_id
    hash[:touched_run_id] = @run_id
    hash
  end

  def finish
    @run_object.finish
  end
end
