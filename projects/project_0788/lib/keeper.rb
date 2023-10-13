require_relative '../models/california_fresno_runs'
require_relative '../models/california_fresno_inmates'
require_relative '../models/california_fresno_arrests'
require_relative '../models/california_fresno_charges'
require_relative '../models/california_fresno_bonds'
require_relative '../models/california_fresno_holding_facilities'
require_relative '../models/california_fresno_court_hearings'
require_relative '../models/california_fresno_inmate_ids'

class Keeper

  def initialize
    @run_object = RunId.new(CaliforniaFresnoRuns)
    @run_id = @run_object.run_id
  end

  DB_MODELS = {'california_fresno_arrests' => CaliforniaFresnoArrests, 'california_fresno_inmates' => CaliforniaFresnoInmates, 'california_fresno_holdings' => CaliforniaFresnoHoldings ,'california_fresno_inmate_ids' => CaliforniaFresnoInmateIds, 'california_fresno_charges' => CaliforniaFresnoCharges, 'california_fresno_bonds' => CaliforniaFresnoBonds, 'california_fresno_court_hearings' => CaliforniaFresnoCourtHearings}

  def insert_for_foreign_key(hash, model)
    DB_MODELS[model].insert(hash)
    id = DB_MODELS[model].where(:md5_hash => hash[:md5_hash]).pluck(:id)[0]
    DB_MODELS[model].where(:md5_hash => hash[:md5_hash]).update_all(:touched_run_id => run_id)
    id
  end

  def insert_data(data, model)
    data.is_a?(Array) ? DB_MODELS[model].insert_all(data) : DB_MODELS[model].insert(data)
    data = [data].flatten
    md5_array = data.map {|e| e[:md5_hash]}
    DB_MODELS[model].where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def marked_deleted
    DB_MODELS.values.each do |value|
      value.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  def finish
    @run_object.finish
  end

  def download_status
    CaliforniaFresnoRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = CaliforniaFresnoRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  attr_accessor :run_id

end
