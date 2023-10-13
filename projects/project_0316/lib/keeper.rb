require_relative '../models/georgia_criminal_offenders'
require_relative '../models/georgia_criminal_offenders_offenses'
require_relative '../models/georgia_criminal_offenders_runs'

class Keeper

  DB_MODELS = {'offenders' => Georgia_criminal_offenders,'offenses' => Georgia_criminal_offenders_offenses}

  def initialize
    @run_object = RunId.new(Georgia_criminal_offenders_run)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mark_delete(key)
    ids_extract = DB_MODELS[key].where(:deleted => 0).group(:gdc_ID).having("count(*) > 1").pluck("gdc_ID, GROUP_CONCAT(id)")
    all_old_ids = ids_extract.map{|e| e.last.split(',').map(&:to_i)}.each{|e| e.delete(e.max)}.flatten
    DB_MODELS[key].where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def already_inserted_md5(key)
    DB_MODELS[key].pluck(:md5_hash)
  end

  def insert_records(data_array,key)
    DB_MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

end
