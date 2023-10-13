require_relative '../models/fl_hc_13jcc_case_runs'
require_relative '../models/fl_hc_13jcc_case_info'
require_relative '../models/fl_hc_13jcc_case_party'
require_relative '../models/fl_hc_13jcc_case_activities'
require_relative '../models/fl_hc_13jcc_case_pdfs_on_aws'
require_relative '../models/fl_hc_13jcc_case_relations_activity_pdf'
require_relative '../models/fl_hc_13jcc_case_relations_info_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(CaseRuns)
    @run_id = @run_object.run_id
  end

  def download_status
    CaseRuns.pluck(:download_status).last
  end

  def mark_delete(dir_interval)
    dates = dir_interval.split('_to_').map{ |e| e.gsub('_', '-').to_date }.reverse
    FlCaseInfo.where('date(case_filed_date) BETWEEN ? AND ?', dates[0], dates[1]).where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def already_inserted_ids
    FlCaseInfo.where(:touched_run_id => run_id).pluck('case_id')
   end

  def finish_download
    current_run = CaseRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def update_touch_run_id(md5_array)
    FlCaseInfo.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end


  def fetch_max_date
    FlCaseInfo.maximum(:case_filed_date)
  end

  attr_reader :run_id

  def make_insertion(model, data_array)
    return if data_array.nil? || data_array.empty?
    model = model.constantize
    model.insert_all([data_array].flatten) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end
end
