require_relative '../models/az_aac2_case_runs'
require_relative '../models/az_aac2_case_additional_info'
require_relative '../models/az_aac2_case_info'
require_relative '../models/az_aac2_case_party'
require_relative '../models/az_aac2_case_pdfs_on_aws'
require_relative '../models/az_aac2_case_relations_info_pdf'
require_relative '../models/az_aac2_case_activities'

class Keeper
  def initialize
    @run_object = RunId.new(AzAaac2CaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_max_year
    AzAac2CaseInfo.maximum(:case_filed_date).year
  end

  def download_status
    AzAaac2CaseRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = AzAaac2CaseRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def inserted_links
    AzAac2CaseInfo.where(run_id: run_id).pluck(:data_source_url)
  end

  def get_max(value)
    value.max
  end

  def update_touched_run_id(info, party, additional_info, activity, aws)
    AzAac2CaseInfo.where(:md5_hash => info).update_all(:touched_run_id => run_id)  unless info.empty?
    AzAac2CaseParty.where(:md5_hash => party).update_all(:touched_run_id => run_id)  unless party.empty?
    AzAac2CaseAdditionalInfo.where(:md5_hash => additional_info).update_all(:touched_run_id => run_id)  unless additional_info.empty?
    AzAac2CaseActivities.where(:md5_hash => activity).update_all(:touched_run_id => run_id)  unless activity.empty?
    AzAac2AwsFiles.where(:md5_hash => aws).update_all(:touched_run_id => run_id)  unless aws.empty?
  end

  def mark_deleted(year)
    case_info_deleted_records = AzAac2CaseInfo.where.not(:touched_run_id => run_id).where("Year(case_filed_date) = '#{year}'").update_all(:deleted => 1)
    if case_info_deleted_records == 0
      return
    else
      deleted_case_id = AzAac2CaseInfo.where.not(:touched_run_id => run_id).where(:deleted => 1).where("Year(case_filed_date) = '#{year}'").pluck(:case_id)
      AzAac2CaseActivities.where.not(:touched_run_id => run_id).where(:case_id => deleted_case_id).update_all(:deleted => 1)
      AzAac2CaseParty.where.not(:touched_run_id => run_id).where(:case_id => deleted_case_id).update_all(:deleted => 1)
      AzAac2AwsFiles.where.not(:touched_run_id => run_id).where(:case_id => deleted_case_id).update_all(:deleted => 1)
      deleteable =  AzAac2CaseInfo.where(:deleted => 1).pluck(:md5_hash)
      AzAac2CaseRelations.where(:case_info_md5 => deleteable).update_all(:deleted => 1)
    end
  end

  def save_activities(data_array)
    AzAac2CaseActivities.insert_all(data_array)
  end

  def save_case_info(data_array)
    AzAac2CaseInfo.insert(data_array)
  end
  
  def save_add_case_info(data_array_add_info)
    AzAac2CaseAdditionalInfo.insert_all(data_array_add_info)
  end

  def save_case_party(party_array)
    AzAac2CaseParty.insert_all(party_array)
  end

  def save_aws(aws_array, relations_array)
    AzAac2AwsFiles.insert(aws_array)
    AzAac2CaseRelations.insert(relations_array)
  end

  def finish
    @run_object.finish
  end
end
