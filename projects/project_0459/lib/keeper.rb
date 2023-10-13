require_relative '../models/pa_padisciplinaryboard_attorneys'
require_relative '../models/pb_runs'

class Keeper
  def initialize
    @run_object = RunId.new(PbRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mark_download_status(id)
    PbRuns.where(id: run_id).update(download_status: "True")
  end

  def download_status(id)
    PbRuns.where(id: run_id).pluck(:download_status)
  end

  def update_touched_run_id(array)
    PaPadisciplinaryboardAttorneys.where(md5_hash: array).update_all(touched_run_id: run_id) unless array.empty?
  end

  def get_deceased_records
    PaPadisciplinaryboardAttorneys.where(current_status: 'Deceased').pluck(:data_source_url)
  end

  def mark_deleted
    bar_ids = PaPadisciplinaryboardAttorneys.where.not(current_status: 'Deceased').pluck(:bar_number)
    PaPadisciplinaryboardAttorneys.where(bar_number: bar_ids).where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def save_record(data_array)
    data_array.count < 5000 ? PaPadisciplinaryboardAttorneys.insert_all(data_array) : data_array.each_slice(5000){|data| PaPadisciplinaryboardAttorneys.insert_all(data)} unless (data_array.nil?) || (data_array.empty?)
  end

  def finish
    @run_object.finish
  end
end
