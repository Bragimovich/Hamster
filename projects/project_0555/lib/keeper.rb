require_relative '../models/ia_sc_case_run'
require_relative '../models/ia_sc_case_info'
require_relative '../models/ia_sc_case_party'
require_relative '../models/ia_sc_case_activities'
require_relative '../models/ia_sc_case_pdfs_on_aws'
require_relative '../models/ia_sc_case_additional_info'
require_relative '../models/ia_sc_case_relations_activity_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(IaCaseRun)
    @run_id = @run_object.run_id
    update_delete_status
  end

  def store_case_info(list_of_hashes)
    IaCaseInfo.insert_all(list_of_hashes)
  end
  
  def store_case_info_add(list_of_hashes)
    IaCaseInfoAdd.insert_all(list_of_hashes)
  end
  
  def store_case_party(list_of_hashes)
    IaCaseParty.insert_all(list_of_hashes)
  end
  
  def store_case_activity(list_of_hashes)
    IaCaseActivity.insert_all(list_of_hashes)
  end
  
  def store_case_pdf_on_aws(list_of_hashes)
    IaCasePdfOnAws.insert_all(list_of_hashes)
  end
  
  def store_case_relations(list_of_hashes)
    IaCaseRelations.insert_all(list_of_hashes)
  end

  def finish
    @run_object.finish
  end

  attr_reader :run_id

  def update_delete_status
    IaCaseInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IaCaseParty.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IaCaseInfoAdd.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IaCaseActivity.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IaCasePdfOnAws.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IaCaseRelations.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def update_touch_run_id(md5_array)
    IaCaseInfo.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    IaCaseParty.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    IaCaseInfoAdd.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    IaCaseActivity.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    IaCasePdfOnAws.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
    IaCaseRelations.where(:md5_hash => md5_array).update_all(:touched_run_id => @run_id) unless md5_array.empty?
  end
end