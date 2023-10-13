require_relative '../models/tx_hcc_case_runs'
require_relative '../models/tx_hcc_case_info'
require_relative '../models/tx_hcc_case_party'
require_relative '../models/tx_hcc_case_activities'

class Keeper
  def initialize
    @run_object = RunId.new(CaseRuns)
    @run_id = @run_object.run_id
  end

  def insert_record(name, data_array)
    model = name.constantize
    model.insert_all(data_array) unless ((data_array.empty? )|| (data_array.nil?))
  end

  def already_inserted_records
    CaseInfo.where(:touched_run_id => run_id).pluck(:case_id)
  end

  def old_records
    CaseInfo.where("status_as_of_date = 'Closed'").pluck(:case_id)
  end

  def mark_download_status(id)
    CaseRuns.where(:id => run_id).update(:download_status => "True")
  end

  def update_touched_run_id(array, name)
    model = name.constantize
    model.where(:md5_hash => array).update_all(:touched_run_id => run_id) unless array.empty?
  end

  def download_status(id)
    CaseRuns.where(:id => run_id).pluck(:download_status)
  end

  def mark_deleted(name, year)
    model = name.constantize
    if name.include? 'Info'
      model.where("Year(case_filed_date) = '#{year}'").where("status_as_of_date = 'Closed'").update_all(:touched_run_id => run_id)
      model.where.not(:touched_run_id => run_id).where("Year(case_filed_date) = '#{year}'").update_all(:deleted => 1)
    else
      case_ids = CaseInfo.where.not(:touched_run_id => run_id).where("Year(case_filed_date) = '#{year}'").where.not("status_as_of_date = 'Closed'").pluck(:case_id)
      model.where.not(:touched_run_id => run_id).where(case_id: case_ids).update_all(:deleted => 1)
    end
  end

  attr_reader :run_id

  def finish
    @run_object.finish
  end
end
