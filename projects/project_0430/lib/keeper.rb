require_relative '../models/va_home_loan_by_state'
require_relative '../models/va_home_loan_by_state_runs'

class Keeper
  def initialize
    @run_object = RunId.new(VaStateRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    VaStateRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = VaStateRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def insert_records(data_array)
    VaState.insert_all(data_array) unless data_array.empty?
  end

  def fetch_db_inserted_links
    VaState.pluck(:data_source_url).uniq
  end

  def finish
    @run_object.finish
  end
end
