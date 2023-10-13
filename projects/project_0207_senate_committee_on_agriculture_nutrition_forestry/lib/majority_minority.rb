# frozen_string_literal: true

require_relative '../models/us_dept_scanf_minority.rb'
require_relative '../models/us_dept_scanf_majority.rb'
require_relative '../lib/us_agriculture_scraper.rb'

class MajorityMinority <  Hamster::Scraper

  MAIN_URL_MINORITY = "https://www.agriculture.senate.gov/newsroom/minority-news?PageNum_rs="
  MAIN_URL_MAJORITY = "https://www.agriculture.senate.gov/newsroom/majority-news?PageNum_rs="

  def initialize
    super
  end

  def main(majority)
    if majority
      maj_object = UsAgricultureScraper.new(MAIN_URL_MAJORITY, UsMajority)
      maj_object.main
    else 
      min_object = UsAgricultureScraper.new(MAIN_URL_MINORITY, UsMinority)
      min_object.main
    end
  end
end
