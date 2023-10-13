require_relative '../models/il_cook__arrestees'
require_relative '../models/il_cook__arrests'
require_relative '../models/il_cook__bonds'
require_relative '../models/il_cook__court_hearings'
require_relative '../models/il_cook__holding_facilities'
require_relative '../models/il_cook__runs'
require_relative '../models/il_cook__mugshots'

class Keeper
  def initialize
    @run_object = RunId.new(IlCookRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_ids
    IlCookArrests.where(status: "In custody").pluck(:booking_number)
  end

  def update_status(array)
    IlCookArrests.where(booking_number: array).update_all(status: "Released") unless array.empty?
    IlCookArrests.where(booking_number: array).update_all(touched_run_id: run_id) unless array.empty?
    IlCookArrests.where(status: "Released").update_all(deleted: 1)
  end

  def common_insertion(data_hash_facility, aws_image_hash)
    IlCookHoldingFacilities.insert(data_hash_facility)
    IlCookMugshots.insert(aws_image_hash) unless aws_image_hash[:aws_link].nil?
  end

  def already_inserted_date
    IlCookArrests.group(:booking_date).pluck(:booking_date)
  end

  def already_inserted_on_same_run_id
    IlCookArrests.where(run_id: run_id).pluck(:booking_number)
  end

  def save_bond(data_hash)
    IlCookBonds.insert(data_hash)
  end

  def save_record(data_hash, model)
    model.constantize.insert(data_hash)
    model.constantize.find_by(md5_hash: data_hash[:md5_hash])[:id]
  end

  def mark_download_status(id)
    IlCookRuns.where(id: run_id).update(download_status: "True")
  end

  def download_status(id)
    IlCookRuns.where(id: run_id).pluck(:download_status)
  end

  def finish
    @run_object.finish
  end
end
