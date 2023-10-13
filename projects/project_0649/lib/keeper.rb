require_relative '../models/pa_bccc_case_activities'
require_relative '../models/pa_bccc_case_info'
require_relative '../models/pa_bccc_case_judgment'
require_relative '../models/pa_bccc_case_party'
require_relative '../models/pa_bccc_case_runs'

class Keeper < Hamster::Scraper

  def initialize
    @run_object = RunId.new(PaBcccCaseRuns)
    @run_id = @run_object.run_id
  end

  def finish_download
    current_run = PaBcccCaseRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    PaBcccCaseRuns.pluck(:download_status).last
  end

  def insert_data(data)
    insert_records(PaBcccCaseInfo, data[0])
    insert_records(PaBcccCaseParty, data[1])
    insert_records(PaBcccCaseActivities, data[2])
    insert_records(PaBcccCaseJudgment, data[3])
  end

  def mark_deleted
    delete_records(PaBcccCaseInfo)
    delete_records(PaBcccCaseParty)
    delete_records(PaBcccCaseActivities)
    delete_records(PaBcccCaseJudgment)
  end

  def update_touch_run_id(info_md5_array, party_md5_array, activities_md5_array, judgment_md5_array)
    update_touch_id(PaBcccCaseInfo, info_md5_array.flatten)
    update_touch_id(PaBcccCaseParty, party_md5_array.flatten)
    update_touch_id(PaBcccCaseActivities, activities_md5_array.flatten)
    update_touch_id(PaBcccCaseJudgment, judgment_md5_array.flatten)
  end

  def finish
    @run_object.finish
  end

  def max_case_file_date
    PaBcccCaseInfo.maximum('case_filed_date')
  end

  def get_already_inserted_links
    PaBcccCaseInfo.where("year(case_filed_date) > 2017").pluck(:data_source_url)
  end

  attr_reader :run_id

  private

  def insert_records(model, data_array)
    data_array.each_slice(5000) { |data| model.insert_all(data) } unless data_array.nil? or data_array.empty?
  end

  def update_touch_id(model, array)
    array.each_slice(5000) { |data| model.where(:md5_hash => data).update_all(:touched_run_id => run_id) }
  end

  def delete_records(model)
    model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

end
