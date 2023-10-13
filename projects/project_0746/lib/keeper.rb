require_relative '../models/colorado_inmates'
require_relative '../models/colorado_arrests'
require_relative '../models/colorado_charges'
require_relative '../models/colorado_court_hearings'
require_relative '../models/colorado_holding_facilities'
require_relative '../models/colorado_inmate_additional'
require_relative '../models/colorado_inmate_ids'
require_relative '../models/colorado_inmates_runs'
require_relative '../models/colorado_inmates'
require_relative '../models/colorado_mugshots'
require_relative '../lib/parser'

class Keeper

  def initialize
    @parser = Parser.new
    @run_object = RunId.new(ColoradoRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_data(data_array, run_id)
    ColoradoInmates.insert(data_array[0]) unless data_array[0].nil?
    ColoradoInmates.where(:md5_hash => [data_array[0][:md5_hash]]).update_all(:touched_run_id => run_id) unless data_array[0].nil?
    immate_id = ColoradoInmates.where(:md5_hash => data_array[0][:md5_hash])[0][:id]
    arrest_hash = @parser.get_arrest_hash(immate_id, run_id)
    ColoradoArrests.insert(arrest_hash)
    ColoradoArrests.where(:md5_hash => [arrest_hash[:md5_hash]]).update_all(:touched_run_id => run_id)
    arrest_id = ColoradoArrests.where(:md5_hash => arrest_hash[:md5_hash])[0][:id]
    insertion_handler(data_array[1], arrest_id, 'arrest_id', ColoradoCharges, run_id)
    insertion_handler(data_array[2], immate_id, 'immate_id', ColoradoAdditional, run_id)
    insertion_handler(data_array[3], arrest_id, 'arrest_id', ColoradoHolding, run_id)
    charge_id = ColoradoCharges.where(:md5_hash => data_array[1][:md5_hash])[0][:id] rescue nil
    insertion_handler(data_array[4], charge_id, 'charge_id', ColoradoHearing, run_id)
    insertion_handler(data_array[5], immate_id, 'immate_id', ColoradoIds, run_id)
    insertion_handler(data_array[6], immate_id, 'immate_id', ColoradoMug, run_id)
  end

  def finish
    @run_object.finish
  end

  def mark_delete
    models = [ColoradoInmates, ColoradoArrests, ColoradoCharges, ColoradoAdditional, ColoradoHolding, ColoradoHearing, ColoradoIds, ColoradoMug]
    models.each do |model|
      model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  private

  def insertion_handler(hash, foreign_id, forign_type, model, run_id)
    return if hash.nil?

    hash[forign_type] = foreign_id
    @parser.commom_hash(hash, run_id)
    model.insert(hash)
    model.where(:md5_hash => [hash[:md5_hash]]).update_all(:touched_run_id => run_id)
  end
end
