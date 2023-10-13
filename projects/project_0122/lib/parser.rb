# frozen_string_literal: true

require_relative '../models/philadelphia_crime_stats_reports'
require_relative '../models/philadelphia_crime_stats_weekly'
require_relative '../models/philadelphia_crime_stats_28_day_period'
require_relative '../models/philadelphia_crime_stats_year_to_date'

class Parser <  Hamster::Scraper

  def initialize
    super
    @processed_weeks = PhiladelphiaCrimeStatsReports.where(:year => Date.today.year).pluck(:week_number)
    @hash_array = []
  end

  def store 
    Dir[("#{storehouse}store/#{Date.today.year}/*pdf")].each do |file_name|
      p file_name
      @week = file_name.split("_").last[0..1]
      next if @processed_weeks.include? @week.to_i
      reader = PDF::Reader.new(open(file_name))
      @document = reader.pages.first.text.scan(/^.+/)
      parser 
    end
  end 

  def parser
    philadelphia_crime_stats_reports
    philadelphia_crime_stats_weekly
    philadelphia_crime_stats_28_day_period
    philadelphia_crime_stats_year_to_date
  end

  def philadelphia_crime_stats_reports
    ind = find_index("CITYWIDE")
    data = @document[ind + 1].split
    data_hash = {}
    
    data_hash = {
      year: Date.today.year,
      week_number: @week,
      start_date: Date.strptime("#{data[2].gsub("(", "")}", "%m/%d/%Y").to_date,
      end_date: Date.strptime("#{data[4].gsub(")", "")}", "%m/%d/%Y").to_date 
    }
    PhiladelphiaCrimeStatsReports.store(data_hash)
    @report_id = PhiladelphiaCrimeStatsReports.limit(1).order("id desc").pluck(:id)[0]
  end

  def philadelphia_crime_stats_weekly 
    crime_section = "Violent Crime"
    week1 = @week.to_i - 1
    week2 = @week.to_i
    start_ind = find_index("Homicide")
    end_ind = find_index("TOTAL #{crime_section.upcase} OFFENSES")
    fetch_data(start_ind, end_ind - 1, week1, crime_section, 0)
    fetch_data(start_ind, end_ind - 1, week2, crime_section, 1)
    
    crime_section = "Property Crime"
    end_ind = find_index("TOTAL #{crime_section.upcase} OFFENSES")
    start_ind = find_index("Burglary/Residential")
    fetch_data(start_ind , (end_ind-1), week1, crime_section, 0)
    fetch_data(start_ind, (end_ind-1), week2, crime_section, 1)
    PhiladelphiaCrimeStatsWeekly.insert_all(@hash_array) if !@hash_array.empty?
    @hash_array = []
  end

  def fetch_data(start_ind, end_ind, week, crime_section, i)
    (start_ind..end_ind).each do |index|
      details = @document[index].split
      crime_type, incident_ind = fetch_crime_type(details)
      data_hash = {}
      data_hash = {
        report_id: @report_id,
        week_number: week,
        crime_section: crime_section,
        crime_type: crime_type,
        number_of_incidents: details[incident_ind + i]
      }  
      @hash_array.push(data_hash)
    end
  end

  def philadelphia_crime_stats_28_day_period
    crime_section = "Violent Crime"
    end_ind = find_index("TOTAL #{crime_section.upcase} OFFENSES")
    
    period_start_date1 = @document.map{ |e| e.scan(/\S\d{2}\S\d{2}\S\d{4}/)}.reject(&:empty?).last.first.split.first.gsub("(", "") 
    period_start_date2 = @document.map{ |e| e.scan(/\S\d{2}\S\d{2}\S\d{4}/)}.reject(&:empty?).last.last.split.first.gsub("(", "")
    peroiod_end_date1 = @document.map{ |e| e.scan(/\d{2}\S\d{2}\S\d{4}\S/)}.reject(&:empty?).last.first.split.first.gsub(")", "")
    peroiod_end_date2 =@document.map{ |e| e.scan(/\d{2}\S\d{2}\S\d{4}\S/)}.reject(&:empty?).last.last.split.first.gsub(")", "")

    period_start_date1 = Date.strptime(period_start_date1, "%m/%d/%Y").to_date
    peroiod_end_date1 = Date.strptime(peroiod_end_date1, "%m/%d/%Y").to_date
    period_start_date2 = Date.strptime(period_start_date2, "%m/%d/%Y").to_date
    peroiod_end_date2 = Date.strptime(peroiod_end_date2, "%m/%d/%Y").to_date

    st_ind = find_index("Homicide")
    fetch_data3(st_ind, end_ind - 1, period_start_date1,peroiod_end_date1, crime_section, 0)
    fetch_data3(st_ind, end_ind - 1, period_start_date2,peroiod_end_date2, crime_section, 1)
    
    crime_section = "Property Crime"
    end_ind = find_index("TOTAL #{crime_section.upcase} OFFENSES")

    st_ind = find_index("Burglary/Residential")
    fetch_data3(st_ind , (end_ind-1), period_start_date1,peroiod_end_date1, crime_section, 0)
    fetch_data3(st_ind, (end_ind-1), period_start_date2,peroiod_end_date2, crime_section, 1)
    
    PhiladelphiaCrimeStats28DayPeriod.insert_all(@hash_array) if !@hash_array.empty?
    @hash_array = []
  end

  def fetch_data3(start_ind, end_ind,period_start_date, peroiod_end_date, crime_section, i )
    (start_ind..end_ind).each do |index|
      details = @document[index].split
      crime_type, incident_ind = fetch_crime_type(details)
      data_hash = {}
      data_hash = {
        report_id: @report_id,
        period_start_date: period_start_date,
        peroiod_end_date:  peroiod_end_date,
        crime_section: crime_section,
        crime_type: crime_type,
        number_of_incidents: details[incident_ind + 2 + i]
      }  
      @hash_array.push(data_hash)
    end
  end

  def philadelphia_crime_stats_year_to_date
    ind = find_index("YEAR TO")
    month_day = @document[ind].split.last
    crime_section = "Violent Crime"
    end_ind = find_index("TOTAL #{crime_section.upcase} OFFENSES")
    st_ind = find_index("Homicide")
    
    date1 = Date.strptime("#{month_day}/#{Date.today.year - 1}", "%m/%d/%Y").to_date
    date2 = Date.strptime("#{month_day}/#{Date.today.year}", "%m/%d/%Y").to_date

    fetch_data2(ind + 3, end_ind - 1, date1, crime_section, 0 ) 
    fetch_data2(ind + 3, end_ind - 1, date2, crime_section, 1 )
    
    crime_section = "Property Crime"
    end_ind = find_index("TOTAL #{crime_section.upcase} OFFENSES")
    st_ind = find_index("Burglary/Residential")

    fetch_data2(st_ind, (end_ind-1), date1, crime_section, 0 )
    fetch_data2(st_ind, (end_ind-1), date2, crime_section, 1 )
  
    PhiladelphiaCrimeStatsYearToDate.insert_all(@hash_array) if !@hash_array.empty?
    @hash_array = []
  end

  def fetch_data2(start_ind, end_ind, date, crime_section, i )
    (start_ind..end_ind).each do |index|
      details = @document[index].split
      crime_type, incident_ind = fetch_crime_type(details)
      data_hash = {}
      data_hash = {
        report_id: @report_id,
        year: date.year,
        to_date:  date,
        crime_section: crime_section,
        crime_type: crime_type,
        number_of_incidents: details[incident_ind + 5 + i]
      }  
      @hash_array.push(data_hash)
    end
  end

  def fetch_crime_type(data)
    crime_type = []
    ind = 0
    data.each_with_index do |text, number|
      ind = number
      break if !text.scan(/(,*\d+,*\d*)+/).empty?
      crime_type << text
    end
    [crime_type.join(" "), ind] 
  end

  def find_index(string)
    check = @document.select{|e| e.include? "#{string}"}
    ind = @document.index check[0]
  end
end
