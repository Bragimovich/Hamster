require_relative '../models/ zip_code_business_patterns'
require_relative '../models/zip_code_business_patterns_run'

class Keeper

  def initialize
    @run_object = RunId.new(ZipCodeBusinessPatternsRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insertion(data_array)
    ZipCodeBusinessPatterns.insert_all(data_array)
  end

  def fetch_years
    ZipCodeBusinessPatterns.select(:year).distinct.map{|e| e[:year] if e[:year] > 2015}
  end

  def finish
    @run_object.finish
  end

end
