require_relative '../models/cdc_covid'
require_relative '../models/cdc_covid_run'

class Keeper
  def initialize
    @run_object = RunId.new(CdcCovidRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    unless data_array.empty?
      data_array.each_slice(10000){|data| CdcCovid.insert_all(data)}
    end
  end

  def finish_download
    current_run = CdcCovidRuns.find_by(id: run_id)
    current_run.update(download_status: 'finish')
  end

  def download_status
    CdcCovidRuns.pluck(:download_status).last
  end

  def update_touch_run_id(md5_array)
    CdcCovid.where(:md5_hash => md5_array).update_all(:touch_run_id => run_id) unless md5_array.empty?
  end

  def del_using_touch_id
    CdcCovid.where.not(:touch_run_id => run_id).update_all(:is_deleted => 1)
  end

  def finish
    @run_object.finish
  end
end
