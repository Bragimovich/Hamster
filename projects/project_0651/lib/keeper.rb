require_relative '../models/almeda_activities'
require_relative '../models/almeda_info'
require_relative '../models/almeda_party'
require_relative '../models/almeda_pdfs'
require_relative '../models/almeda_activity_pdf_relation'
require_relative '../models/almeda_runs'
require_relative '../models/ca_acsc_case_relations_info_pdf'

class Keeper

  def initialize
    @run_object = RunId.new(AlmedaRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    AlmedaRuns.pluck(:download_status).last
  end

  def insert_records(info, activities, party, pdfs, relation, info_relations_hash)
    insert_data(AlmedaCaseInfo, info)
    insert_data(AlmedaActivities, activities)
    insert_data(AlmedaCaseParty, party)
    insert_data(AlmedaPdfsOnAws, pdfs)
    insert_data(AlmedaActivityRelationPdf, relation)
    insert_data(AlmedaActivityRelationInfo, info_relations_hash)
  end

  def finish
    @run_object.finish
  end

  def max_file_date
    AlmedaCaseInfo.maximum('case_filed_date')
  end

  def already_inserted_ids
    AlmedaCaseInfo.where(:touched_run_id => run_id).pluck('case_id')
   end

  def insert_data(model, data_array)
    model.insert_all(data_array) unless  data_array.nil? || data_array.empty?
  end

  def update_touch_run_id(md5_array)
    AlmedaCaseInfo.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def delete_using_touch_id(date)
    AlmedaCaseInfo.where.not(:touched_run_id => run_id).where("Date(case_filed_date) = '#{date}'").update_all(:deleted => 1)
  end

  def finish_download
    current_run = AlmedaRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def finish
    @run_object.finish
  end

end
