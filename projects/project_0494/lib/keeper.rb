require_relative '../models/mn_saac_case_runs'
require_relative '../models/mn_saac_case_info'
require_relative '../models/mn_saac_case_party'
require_relative '../models/mn_saac_case_activities'
require_relative '../models/mn_saac_case_pdfs_on_aws'
require_relative '../models/mn_saac_case_relations_activity_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(MnSaacCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mark_deleted
    records = MnSaacCaseInfo.where(:deleted => 0).group(:data_source_url).having("count(*) > 1")
    records.each do |record|
      relations_table = MnSaacCaseRelations.where(:case_info_md5_hash => record[:md5_hash])
      relations_table[0].update(:deleted => 1)
      record.update(:deleted => 1)
    end
  end

  def get_inserted_pdfs
    MnSaacAwsFiles.pluck(:aws_link)
  end

  def get_max_year
    MnSaacCaseInfo.maximum(:case_filed_date).year
  end

  def get_inserted_records
    MnSaacCaseInfo.where(run_id: run_id).pluck(:data_source_url)
  end

  def save_activities(data_array)
    MnSaacCaseActivities.insert_all(data_array)
  end

  def save_case_info(data_array)
    MnSaacCaseInfo.insert(data_array)
  end
  
  def save_case_party(party_array)
    MnSaacCaseParty.insert_all(party_array)
  end

  def save_aws(aws_array, relations_array)
    MnSaacAwsFiles.insert_all(aws_array)
    MnSaacCaseRelations.insert_all(relations_array)
  end

  def finish
    @run_object.finish
  end
end
