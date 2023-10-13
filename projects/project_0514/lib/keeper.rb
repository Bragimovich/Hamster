require_relative '../models/eada_equity_in_athletic'
require_relative '../models/eada_equity_in_athletic_runs'

class Keeper
  def initialize
    @run_object = RunId.new(EADA_Runs)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_max_year
    EADA.maximum(:year)
  end

  def save_record(data_array)
    EADA.insert_all(data_array)
  end

  def mark_download_status(id)
    EADA_Runs.where(:id => run_id).update(:download_status => "True")
  end

  def download_status(id)
    EADA_Runs.where(:id => run_id).pluck(:download_status)
  end

  def finish
    @run_object.finish
  end
end
