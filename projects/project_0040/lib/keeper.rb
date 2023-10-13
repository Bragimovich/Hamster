require_relative '../models/Delaware_business_licenses_runs'
require_relative '../models/Delaware_business_licenses'

class Keeper
  def initialize
    @run_object = RunId.new(DelawareBusinessLicensesRuns)
    @run_id = @run_object.run_id
  end
  
  attr_reader :run_id
  
  def fetch_db_inserted_md5_hash
    DelawareBusinessLicenses.pluck(:md5_hash)
  end
  
  def deletion(db_processed_md5)
    db_processed_md5.each{|e|
    DelawareBusinessLicenses.where(:md5_hash => e).update_all(:is_deleted => 1)
  }
  end
  
  def save_record(data_array)
    DelawareBusinessLicenses.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end
end
