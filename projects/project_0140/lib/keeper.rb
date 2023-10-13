require_relative '../models/equities'
require_relative '../models/equities_prices'
require_relative '../models/equities_info'
require_relative '../models/equties_ft_runs'

class Keeper

  def initialize
    @run_object = RunId.new(EqutiesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_links
    Equities.pluck(:equity_url).uniq
  end

  def fetch_already_inserted_equties
    Equities.pluck(:equity_symbol)
  end

  def insert_prices(data_array)
    EquitiesPrices.insert_all(data_array)
  end

  def insert_equities(data_array)
    Equities.insert_all(data_array)
  end

  def fetch_equities_price
    EquitiesPrices.pluck(:data_source_url).uniq
  end

  def insert_info(data_array)
    EquitiesInfo.insert_all(data_array)
  end

  def set_is_deleted
    need_to_set_deleted = EquitiesPrices.where(:is_deleted => 0).pluck(:id, :data_as_of).select{|e| (Date.today - Date.parse(e.last.to_s.split.first)).to_i > 7}
    all_old_ids = need_to_set_deleted.map { |e| e[0] }
    unless all_old_ids.empty?
      all_old_ids.count < 5000 ? mark_prices_deleted(all_old_ids) : all_old_ids.each_slice(5000) { |data| mark_prices_deleted(data) }
    end
    mark_ids_delete('price')
  end

  def mark_prices_deleted(ids)
    EquitiesPrices.where(:id => ids).update_all(:is_deleted => 1)
  end

  def mark_ids_delete(value)
    model = value == 'info' ? EquitiesInfo : EquitiesPrices
    ids_extract = model.where(:is_deleted => 0).group(:data_source_url).having("count(*) > 1").pluck("data_source_url, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i)
      ids.delete get_max(ids)
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    model.where(:id => all_old_ids).update_all(:is_deleted => 1)
  end

  def set_is_deleted_info
    mark_ids_delete('info')
  end

  def get_max(value)
    value.max
  end

  def finish
    @run_object.finish
  end
end
