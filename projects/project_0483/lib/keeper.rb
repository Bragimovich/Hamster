require_relative '../models/tn_saac_case_runs'
require_relative '../models/tn_saac_case_info'
require_relative '../models/tn_saac_case_additional_info'
require_relative '../models/tn_saac_case_consolidations'
require_relative '../models/tn_saac_case_party'
require_relative '../models/tn_saac_case_activities'
require_relative '../models/tn_saac_case_pdfs_on_aws'
require_relative '../models/tn_saac_case_relations_activity_pdf'
require_relative '../models/tn_saac_case_relations_info_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(TnSaacCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_already_inserted_links
    TnSaacCaseInfo.where(run_id: run_id).pluck(:data_source_url)
  end

  def alread_downloaded_pdfs_count(url)
    TnSaacCasePdfsOnAws.where(source_link: url).pluck(:id).count - 1
  end

  def mark_deleted
    TnSaacCaseInfo.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    TnSaacCaseParty.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    TnSaacCaseAdditionalInfo.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    TnSaacCaseActivities.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    TnSaacCasePdfsOnAws.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    deleteable =  TnSaacCaseInfo.where(:deleted => 1).pluck(:md5_hash)
    TnSaacCaseRelationsInfoPdf.where(:case_info_md5 => deleteable).update_all(:deleted => 1)
  end

  def download_status
    TnSaacCaseRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = TnSaacCaseRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def touched_run_id_process(info_md5_hash, party_md5, activity_md5, additional_md5_hash, aws_pdf_md5_hash)
    update_touched_run_id(TnSaacCaseInfo, info_md5_hash)
    update_touched_run_id(TnSaacCaseParty, party_md5)
    update_touched_run_id(TnSaacCaseActivities, activity_md5)
    update_touched_run_id(TnSaacCaseAdditionalInfo, additional_md5_hash)
    update_touched_run_id(TnSaacCasePdfsOnAws, aws_pdf_md5_hash)
  end

  def update_touched_run_id(model, md5_hash_array)
    model.where(:md5_hash => md5_hash_array).update_all(:touched_run_id => run_id)  unless md5_hash_array.empty? rescue nil
  end
  
  def save_record(info_hash, party_array, actvities_array, additional_info_array, aws_pdf_array, activity_relations_array, data_relations_info_hash)
    TnSaacCaseInfo.insert(info_hash) unless info_hash.nil?
    TnSaacCaseAdditionalInfo.insert_all(additional_info_array) unless additional_info_array.empty?
    TnSaacCaseParty.insert_all(party_array) unless party_array.empty?
    TnSaacCaseActivities.insert_all(actvities_array) unless actvities_array.empty?
    TnSaacCaseRelationsActivityPdf.insert_all(activity_relations_array) unless activity_relations_array.empty?
    TnSaacCaseRelationsInfoPdf.insert(data_relations_info_hash) unless data_relations_info_hash.nil?
    TnSaacCasePdfsOnAws.insert_all(aws_pdf_array) unless aws_pdf_array.empty?
  end

  def finish
    @run_object.finish
  end
end
