require_relative '../models/co_saac_case_run'
require_relative '../models/co_saac_case_info'
require_relative '../models/co_saac_case_party'
require_relative '../models/co_saac_case_activities'
require_relative '../models/co_saac_case_pdfs_on_aws'
require_relative '../models/co_saac_case_additional_info'
require_relative '../models/co_saac_case_relations_info_pdf'
require_relative '../models/co_saac_case_relations_activity_pdf'

class Keeper
  CHUNK = 1000

  def initialize
    @run_object = RunId.new(CoSaacCaseInfoRun)
    @run_id = @run_object.run_id
  end

  def create_status(status)
    @run_id = CoSaacCaseInfoRun.create(status: status).id
  end

  def update_status(status)
    CoSaacCaseInfoRun.where(id: @run_id).update_all(status: status)
  end

  def get_last_run
    CoSaacCaseInfoRun.last
  end

  def delete_history
    CoSaacCaseInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    CoSaacCaseParty.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    CoSaacCaseActivity.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    CoSaacCaseInfoAdd.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    CoSaacCasePdfOnAws.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    CoSaacCaseInfoRelations.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    CoSaacCaseActivityRelations.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end
  
  def update_touch_run_id(md5_array)
    CoSaacCaseInfo.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    CoSaacCaseParty.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    CoSaacCaseActivity.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    CoSaacCaseInfoAdd.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    CoSaacCasePdfOnAws.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    CoSaacCaseInfoRelations.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    CoSaacCaseActivityRelations.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
  end
  
  def finish
    @run_object.finish
  end

  def store_all(records, model)
    return if records.empty?

    records.each_slice(CHUNK) do |chunk|
      case model
      when "info"
        CoSaacCaseInfo.insert_all chunk
      when "party"
        CoSaacCaseParty.insert_all chunk
      when "activities"
        CoSaacCaseActivity.insert_all chunk
      when "add_info"
        CoSaacCaseInfoAdd.insert_all chunk
      when "pdfs_on_aws"
        CoSaacCasePdfOnAws.insert_all chunk
      when "rel_info_pdf"
        CoSaacCaseInfoRelations.insert_all chunk
      when "rel_act_pdf"
        CoSaacCaseActivityRelations.insert_all chunk
      end
    rescue StandardError => e
      next
      print_all e, e.full_message, title: " ERROR "
      send_to_slack("project_0594 error in store_all:\n#{e.inspect}")
    end
  end
end