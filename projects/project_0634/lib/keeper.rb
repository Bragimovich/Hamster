require_relative '../models/la_1c_ac_case_activities'
require_relative '../models/la_1c_ac_case_info'
require_relative '../models/la_1c_ac_case_party'
require_relative '../models/la_1c_ac_case_pdfs_on_aws'
require_relative '../models/la_1c_ac_case_relations_activity_pdf'
require_relative '../models/la_1c_ac_case_runs'

class Keeper

  def initialize
    @run_object = RunId.new(La1cAcCaseRuns)
    @run_id = @run_object.run_id
  end

  def save_on_la_1c_ac_case_info(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    La1cAcCaseInfo.insert(data)
  end

  def save_on_la_1c_ac_case_activities(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    La1cAcCaseActivities.insert(data)
  end

  def save_on_la_1c_ac_case_party(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    La1cAcCaseParty.insert(data)
  end

  def save_on_la_1c_ac_case_pdfs_on_aws(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    La1cAcCasePDFsOnAws.insert(data)
  end

  def save_on_la_1c_ac_case_relations_activity_pdf(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    La1cAcCaseRelationsActivityPDF.insert(data)
  end

  def finish
    @run_object.finish
  end
end