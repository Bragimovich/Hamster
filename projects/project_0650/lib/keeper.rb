require_relative '../models/pa_ccpbc_case_info'
require_relative '../models/pa_ccpbc_case_party'
require_relative '../models/pa_ccpbc_case_runs'
require_relative '../models/pa_ccpbc_case_judgment'
require_relative '../models/pa_ccpbc_case_activities'
require_relative '../models/pa_ccpbc_case_pdfs_on_aws'
require_relative '../models/pa_ccpbc_case_relations_activity_pdf'
require_relative '../models/pa_ccpbc_case_relations_info_pdf'

class Keeper

  def initialize
    @run_object = RunId.new(CaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_case(name, data_array)
    model = name.constantize
    model.insert_all(data_array.flatten) unless ((data_array.nil?) || (data_array.empty?))
  end

  def mark_download_status(id)
    CaseRuns.where(id: run_id).update(download_status: "True")
  end

  def update_touched_run_id(array, name)
    model = name.constantize
    model.where(md5_hash: array).update_all(touched_run_id: run_id) unless ((array.nil?) || (array.empty?))
  end

  def download_status(id)
    CaseRuns.where(id: run_id).pluck(:download_status)
  end

  def mark_deleted(name)
    model = name.constantize
    model.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end
end
