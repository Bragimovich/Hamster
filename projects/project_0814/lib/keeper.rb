require_relative '../models/ut_utah_inmate_statuses'
require_relative '../models/ut_utah_inmate_additional_info'
require_relative '../models/ut_utah_holding_facilities'
require_relative '../models/ut_utah_court_hearings'
require_relative '../models/ut_utah_bonds'
require_relative '../models/ut_utah_inmates_runs'
require_relative '../models/ut_utah_charges'
require_relative '../models/ut_utah_arrests'
require_relative '../models/ut_utah_inmate_ids'
require_relative '../models/ut_utah_inmates'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(InmatesRuns)
    @run_id = @run_object.run_id
  end

  def insert_data(hash, model)
    model = model.constantize
    model.insert(hash)
    model.where(:md5_hash => [hash[:md5_hash]]).update_all(:touched_run_id => run_id)
    model.where(:md5_hash => hash[:md5_hash]).pluck(:id)[0]
  end

  def store(data_array, model)
    model = model.constantize
    data_array.each_slice(5000) { |data| model.insert_all(data) }
    md5_hash_array = data_array.map { |e| e[:md5_hash] }
    md5_hash_array.each_slice(5000) { |data| model.where(:md5_hash => data).update_all(:touched_run_id => run_id) }
  end

  def finish
    @run_object.finish
  end

  def mark_delete
    models = [UtUtahInmateAdditionalInfo, UtUtahInmateStatuses, UtUtahInmateIds, UtUtahHoldingFacilities, UtUtahBonds, UtUtahCourtHearings, UtUtahInmates, UtUtahArrests, UtUtahCharges]
    models.each do |model|
      model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end
end
