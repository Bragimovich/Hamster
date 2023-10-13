require_relative '../models/va_saac_case_additional_info'
require_relative '../models/va_saac_case_info'
require_relative '../models/va_saac_case_party'
require_relative '../models/va_saac_case_pdfs_on_aws'
require_relative '../models/va_saac_case_runs'
require_relative '../models/va_saac_case_relations_info_pdf'

class Keeper

  def initialize
    @run_object = RunId.new(VaSaacCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_inactive_records_db
    VaSaacCaseInfo.where("status_as_of_date =  'Inactive'").pluck(:data_source_url).map{|url| url.scan(/\d+/).first}
  end

  def fetch_db_info_md5
    VaSaacCaseInfo.pluck(:md5_hash)
  end

  def fetch_db_party_md5
    VaSaacCaseParty.pluck(:md5_hash)
  end

  def save_case_info(data_array)
    VaSaacCaseInfo.insert_all(data_array)
  end
  
  def save_add_case_info(data_array_add_info)
    VaSaacCaseAdditionalInfo.insert_all(data_array_add_info)
  end

  def save_case_party(party_array)
    VaSaacCaseParty.insert_all(party_array)
  end

  def save_aws(aws_array, relations_array)
    VaSaacCaseAwsFiles.insert_all(aws_array)
    VaSaacCaseRelations.insert_all(relations_array)
  end

  def mark_deleted(court_id)
    records = VaSaacCaseInfo.where(:deleted => 0, :court_id => court_id).group(:case_id).having("count(*) > 1")
    records.each do |record|
      VaSaacCaseInfo.where(:case_id => record[:case_id]).order(id: :desc).offset(1).update_all(:deleted => 1)
      relation_records = VaSaacCaseInfo.where(:case_id => record[:case_id], :deleted => 1).pluck(:md5_hash)
      VaSaacCaseRelations.where(:case_info_md5 => relation_records).update_all(:deleted => 1)
    end
  end

  def update_touch_run_id(add_info_md5_array , info_md5_array, party_md5_array , aws_md5_array)
    VaSaacCaseAdditionalInfo.where(:md5_hash => add_info_md5_array).update_all(:touched_run_id => run_id) unless add_info_md5_array.empty?
    VaSaacCaseInfo.where(:md5_hash => info_md5_array).update_all(:touched_run_id => run_id) unless info_md5_array.empty?
    VaSaacCaseParty.where(:md5_hash => party_md5_array).update_all(:touched_run_id => run_id) unless party_md5_array.empty?
    VaSaacCaseAwsFiles.where(:md5_hash => aws_md5_array).update_all(:touched_run_id => run_id) unless aws_md5_array.empty?
  end

  def finish
    @run_object.finish
  end
end
