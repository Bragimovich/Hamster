require_relative '../models/cook_county_influenza_weekly_report'
require_relative '../models/cook_county_influenza_weekly_report_runs'

class Keeper
  def initialize
    @run_object = RunId.new(CookCountryInfluenzaRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_hash)
    CookCountryInfluenzaReport.insert_all(data_hash)
  end

  def fetch_db_inserted_links
    CookCountryInfluenzaReport.pluck(:link)
  end

  def finish
    @run_object.finish
  end
end
