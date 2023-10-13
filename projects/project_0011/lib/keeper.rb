require_relative '../models/sba_ppp_csv'
require_relative '../models/sba_ppp_csv_runs'

class Keeper
  def initialize
    @run_object = RunId.new(SbaPppCsvRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    SbaPppCsvRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = SbaPppCsvRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def db_inserted_files
    SbaPppCsv.where(run_id: run_id).pluck(:file_name).uniq
  end

  def insert_date(current_date)
    SbaPppCsvRuns.where(id: run_id).update(scraper_date: current_date)
  end

  def fetch_latest_scrape_date
    SbaPppCsv.pluck(:last_scrape_date).last
  end

  def update_touched_run_id(loan_numbers)
    SbaPppCsv.where(LoanNumber: loan_numbers).where.not(deleted: 1).update_all(:touched_run_id => run_id)
  end

  def insert_records(data_array)
    SbaPppCsv.insert_all(data_array)
  end

  def mark_delete
    SbaPppCsv.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end

end
