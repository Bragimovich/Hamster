# frozen_string_literal: true

require 'roo'
require_relative '../models/new_york_city_crime_statistics_weekly'

class CrimeComplaints < Hamster::Parser

  def initialize(sheet)
    @sheet = sheet
    super
  end
  
  def need_update?
    date = Date.strptime(report_start_date, '%m/%d/%Y')
    max_date = NewYorkCityCrimeStatisticsWeekly.maximum('report_start_date') || 0
    date > max_date
  end
  
  def run
    return unless need_update?

    (0..16).to_a.each do |i|
      row = NewYorkCityCrimeStatisticsWeekly.new
      row.crime_category = crime_category(i)
      row.year_1 = year_1
      row.year_2 = year_2
      row.report_start_date = Date.strptime(report_start_date, '%m/%d/%Y')
      row.report_end_date = Date.strptime(report_end_date, '%m/%d/%Y')
      row.week_to_date_year1 = week_to_date_year1(i)
      row.week_to_date_year2 = week_to_date_year2(i)
      row.year_to_date_year1 = year_to_date_year1(i)
      row.year_to_date_year2 = year_to_date_year2(i)
      row.last_28_days_year1 = last_28_days_year1(i)
      row.last_28_days_year2 = last_28_days_year2(i)
      row.save
    end
  end
  
  private

  def report_start_date
    @sheet.row(9)[2].gsub('Report Covering the Week  ', '').split('Through')[0].strip
  end

  def report_end_date
    @sheet.row(9)[2].gsub('Report Covering the Week  ', '').split('Through')[1].strip
  end

  def year_1
    @sheet.row(13)[3]
  end

  def year_2
    @sheet.row(13)[2]
  end

  def crime_category(i)
    @sheet.row(14 + i)[0]
  end

  def week_to_date_year1(i)
    @sheet.row(14 + i)[3]
  end

  def week_to_date_year2(i)
    @sheet.row(14 + i)[2]
  end

  def year_to_date_year1(i)
    @sheet.row(14 + i)[9]
  end

  def year_to_date_year2(i)
    @sheet.row(14 + i)[8]
  end

  def last_28_days_year1(i)
    @sheet.row(14 + i)[6]
  end

  def last_28_days_year2(i)
    @sheet.row(14 + i)[5]
  end
end

