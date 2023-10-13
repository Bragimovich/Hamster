require_relative '../models/idaho'
require_relative '../models/idaho_runs'
require_relative '../models/usa_administrative_division_states'

class Keeper

  def initialize
    @run_object = RunId.new(IdahoRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mark_deleted
    records = Idaho.where(:deleted => 0).group(:link).having("count(*) > 1")
    records.each do |record|
      record.update(:deleted => 1)
    end
  end

  def save_record(data_array)
    Idaho.insert_all(data_array)
  end

  def fetch_already_inserted_links
    Idaho.where(run_id: run_id).pluck(:link)
  end

  def fetch_us_states
    USAStates.all().map {|row| row[:short_name]}
  end

  def already_inserted_hashes
    Idaho.pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end
end
