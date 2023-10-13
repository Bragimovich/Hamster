require_relative '../models/il_higher_ed_salaries_run'
require_relative '../models/il_higher_ed_salaries'

class Keeper

  def initialize
    @run_object = RunId.new(IlSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def finish_download
    current_run = IlSalariesRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def save_record(data_array)
    IlSalaries.insert_all(data_array)
  end

  def delete_using_touch_id
    IlSalaries.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def update_touch_run_id(records_md5_hashes)
    IlSalaries.where(:md5_hash => records_md5_hashes).update_all(:touched_run_id => run_id) unless records_md5_hashes.empty?
  end

  def download_status
    IlSalariesRuns.pluck(:download_status).last
  end

  def already_fetched_records(year)
    IlSalaries.where(:touched_run_id => run_id, year: year).pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end
end
