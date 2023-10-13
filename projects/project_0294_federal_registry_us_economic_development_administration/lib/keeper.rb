require_relative '../models/us_dept_eda'
require_relative '../models/us_dept_eda_runs'
require_relative '../models/tags'

class Keeper
  def initialize
    @run_object = RunId.new(UsDeptEdaRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_record(data_hash)
    UsDeptEda.insert(data_hash)
  end

  def insert_tags(tag_array)
    UsDeptEdaTags.insert_all(tag_array)
  end

  def fetch_db_inserted_links
    UsDeptEda.pluck(:link)
  end

  def finish
    @run_object.finish
  end

end
