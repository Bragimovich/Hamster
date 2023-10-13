require_relative '../models/ga_gwinnett_arrests'
require_relative '../models/ga_gwinnett_bonds'
require_relative '../models/ga_gwinnett_charges'
require_relative '../models/ga_gwinnett_court_hearings'
require_relative '../models/ga_gwinnett_holding_facilities_addresses'
require_relative '../models/ga_gwinnett_holding_facilities'
require_relative '../models/ga_gwinnett_immate_ids'
require_relative '../models/ga_gwinnett_immates'
require_relative '../models/ga_gwinnett_runs'

class Keeper

  DB_MODELS = {
    "arrest" => GaGwinnettArrests,
    "bonds" => GaGwinnettBonds,
    "charges" => GaGwinnettCharges,
    "court" => GaGwinnettCourtHearings,
    "holding_facilities" => GaGwinnettHoldingFacilities,
    "holding_address" => GaGwinnettHoldingFacilitiesAddresses,
    "inmates_ids" => GaGwinnettImmatesIds,
    "inmates" => GaGwinnettImmates
  }


  def initialize
    @run_object = RunId.new(GaGwinnettRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_record(key, data_hash)
    data_hash.each do |data|
      DB_MODELS[key].insert(data)
    end
  end

  def insert_return_id(key,data_hash)
    DB_MODELS[key].insert(data_hash)
    sleep(0.25)
    DB_MODELS[key].find_by(md5_hash: data_hash[:md5_hash])[:id]
  end

  def get_booking_number
    GaGwinnettArrests.where(touched_run_id: run_id).pluck(:booking_number)
  end

  def finish_download
    current_run = GaGwinnettRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    GaGwinnettRuns.pluck(:download_status).last
  end

  def update_touch_run_id(md5_array)
    GaGwinnettArrests.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def delete_using_touch_id
    GaGwinnettArrests.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end

end
