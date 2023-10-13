require_relative '../models/ca_kcsc_case_info'
require_relative '../models/ca_kcsc_case_party'
require_relative '../models/ca_kcsc_case_activities'
require_relative '../models/ca_kcsc_case_pdfs_on_aws'
require_relative '../models/ca_kcsc_case_relations_activities_pdf'
require_relative '../models/ca_kcsc_case_runs'

class Keeper

  def initialize
    @run_object = RunId.new(CaKcscCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    CaKcscCaseRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = CaKcscCaseRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def insert_info(hash)
    CaKcscCaseInfo.insert(hash)
  end

  def insert_activity(array)
    CaKcscCaseActivities.insert_all(array)
  end

  def insert_pdf_aws_hash(aws_hash_array)
    CaKcscCasePdfOnAws.insert_all(aws_hash_array)
  end

  def insert_pdf_activity_relation(relations_hash_array)
    CaKcscCaseRelationsActivitiesPdf.insert_all(relations_hash_array)
  end

  def insert_party(array)
    CaKcscCaseParty.insert_all(array)
  end

  def mark_delete
    ids_extract = CaKcscCaseInfo.where(:deleted => 0).group(:case_id).having("count(*) > 1").pluck("case_id, GROUP_CONCAT(id)")
    all_old_ids = ids_extract.map{|e| e.last.split(',').map(&:to_i)}.each{|e| e.delete(e.max)}.flatten
    unless all_old_ids.empty?
      all_old_ids.count < 5000 ? mark_ids_deleted(all_old_ids) : all_old_ids.each_slice(5000) { |data| mark_ids_deleted(data) }
    end
  end

  def mark_ids_deleted(ids)
    CaKcscCaseInfo.where(:id => ids).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end

end
