# frozen_string_literal: true

require 'roo'
require_relative '../models/new_york_city_crime_statistics_weekly'
require_relative '../models/new_york_city_crime_statistics_yearly_history'

class HistoricalPerspective < Hamster::Parser

  def initialize(sheet)
    @sheet = sheet
    super
  end
  
  def need_update?
    existing_years = NewYorkCityCrimeStatisticsYearlyHistory.distinct.pluck(:year)
    years =  @sheet.row(35).select { |element| is_number?(element) }.map(&:to_s)
    years & existing_years != years
  end
  
  def run
    return unless need_update?
    @run_id = (NewYorkCityCrimeStatisticsYearlyHistory.maximum('run_id') || 0 ) + 1

    [2,4,6,8,9].each do |year_index|
      (0..7).to_a.each do |i|
        row = NewYorkCityCrimeStatisticsYearlyHistory.new
        row.run_id = @run_id
        row.crime_category = crime_category(i)
        row.year = year(year_index)
        row.amount_of_crimes= amount_of_crimes(i, year_index)
        row.save
      end
    end
  end
  
  private

  def is_number? string
    true if Float(string) rescue false
  end

  def year(index)
    @sheet.row(35)[index]
  end

  def crime_category(i)
    @sheet.row(36 + i)[0]
  end

  def amount_of_crimes(i, year_index)
    @sheet.row(36 + i)[year_index]
  end
end

