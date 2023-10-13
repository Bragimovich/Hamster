# frozen_string_literal: true

require 'zip'
require_relative '../models/new_residential_construction_data'
require_relative '../models/new_residential_construction_time_periods'

class Scraper < Hamster::Scraper

  FILE_NAME = Time.now.strftime('%Y-%m').gsub('-', '_')
  TIME_PERIODS = NewResidentialConsructionTimePeriod
  MAIN_DATA = NewResidentialConstructionData

  def download
    move_to_trash
    input =
      Hamster.connect_to('https://www.census.gov/econ_getzippedfile/?programCode=RESCONST') do |response|
        response.headers[:content_type].match?(/stream/)
      end.body
    Zip::File.open_buffer(input) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name.include? 'csv'
        Zlib::GzipReader.open(peon.put(file: "#{FILE_NAME}", content: entry.get_input_stream.read), &:read)
      end
    rescue => e
      message = <<~MSG
              !!! --- ERROR in #80 mm_new_residential_construction Problem with download--- !!!
        #{e.backtrace.map.with_index { |s, i| i.zero? ? "`#{s.gsub(/`/, "'")}`" : "\t#{i}: from `#{s.gsub(/`/, "'")}`" }
           .reverse
           .join("\n")}
      MSG
      Hamster.report(to: 'Yunus Ganiyev', message: message)
    end

    puts 'File downloaded!'
  end

  def parse_file
    file = peon.give(file: FILE_NAME)
    parts = file.split("\r\n\n\n")
    get_time_periods(parts[4].split("per_name\r\n").last)
    result = get_main_data(parts[7].split('val').last.strip)
    report_date = Date.strptime(parts[6].split(', ').last, '%d-%b-%y')

    result.each do |h|
      h[:data_source_url] = 'https://www.census.gov/econ_datasets/'
      h[:scrape_frequency] = 'monthly'
      h[:created_by] = 'Yunus Ganiyev'
      h[:report_date] = report_date
      h[:last_scrape_date] = Date.today
      h[:next_scrape_date] = Date.today + 1.month
      h[:expected_scrape_frequency] = 'monthly'
      h[:dataset_name_prefix] = 'mm_new_residential_construction'
      h[:scrape_status] = 'live'
      h[:pl_gather_task_id] = 7_596
      h[:created_date] = Time.now
    end
    fill_main_data(result)
  end

  private

  def get_time_periods(file)
    time_period = []
    file.each_line { |line| time_period << line.chomp }
    per_idx, per_name = time_period.last.split(',')
    last_per_idx = TIME_PERIODS.last[:per_idx]
    per_idx = per_idx.to_i
        if per_idx - last_per_idx > 1
          message =
            "!!! --- `ERROR in #80 mm_new_residential_construction`\n
    It looks like an iteration has been skipped. Last per_idx = *`#{per_idx}`* , current per_idx = *`#{last_per_idx}`* --- !!!"
          Hamster.report(to: 'Yunus Ganiyev', message: message)
          raise
        end
    fill_time_periods(per_idx, per_name.gsub('-', '')) if per_idx > last_per_idx
  end

  def fill_time_periods(per_idx, per_name)
    h = {
      data_source_url: 'https://www.census.gov/econ_datasets',
      per_idx: per_idx,
      per_name: per_name,
      scrape_frequency: 'monthly',
      created_by: 'Yunus Ganiyev',
      created_date: Time.now
    }
    TIME_PERIODS.insert(h)
  end

  def get_main_data(file)
    keys = %w[per_idx cat_idx dt_idx et_idx geo_idx is_adj val]
    data = []
    file.split("\r\n").each do |line|
      vals = line.strip.split(',')
      data << vals[0..-2].map(&:to_i) + [vals.last.to_f]
    end
    result = data.map { |n| Hash[keys.map(&:to_sym).zip(n)] }
    if MAIN_DATA.last.nil?
      result.sort_by! { |k| [k[:per_idx], k[:cat_idx], k[:dt_idx]] }
    else
      prev_period = TIME_PERIODS.last[:per_idx] - 1
      period = MAIN_DATA.where(per_idx: prev_period).empty? ? prev_period : prev_period + 1
      result = result.select { |el| el[:per_idx] >= period }
      result.sort_by! { |k| [k[:per_idx], k[:cat_idx], k[:dt_idx]] }
    end
  end

  def fill_main_data(result)
    MAIN_DATA.insert_all(result) unless result.empty?
  end

  def move_to_trash
    peon.list.each do |file|
      peon.move(file: file)
    end
  end
end



