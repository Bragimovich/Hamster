require_relative '../models/cook_county'
require_relative '../models/cook_county_runs'

class Keeper
  def initialize
    @run_object = RunId.new(CookCountyRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    dump_array = []
    data_array.each do |record|
      dump_array << record
      if dump_array.count == 5000
        CookCounty.insert_all(dump_array)
        dump_array = []
      end
    end
    CookCounty.insert_all(dump_array) unless dump_array.empty?
  end

  def fetch_md5
    CookCounty.where(:deleted => 0).pluck(:md5_hash)
  end

  def mark_deleted
    records = CookCounty.where(:deleted => 0).group(:case_number).having("count(*) > 1").pluck(:case_number)
    records.each do |record|
      CookCounty.where(:case_number => record).order(id: :desc).offset(1).update_all(:deleted => 1)
    end
  end 

  def finish
    @run_object.finish
  end

end
