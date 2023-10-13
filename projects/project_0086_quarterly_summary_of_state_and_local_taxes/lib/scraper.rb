# frozen_string_literal: true

require 'zip'
require_relative '../models/quarterly_summary_of_state_and_local_taxes_data'
require_relative '../models/quarterly_summary_of_state_and_local_taxes_time_period'

class Scraper < Hamster::Scraper

  FILE_NAME = Time.now.strftime('%Y-%m').gsub('-', '_')
  TIME_PERIODS = QuarterlySummaryOfStateAndLocalTaxesTimePeriod
  MAIN_DATA = QuarterlySummaryOfStateAndLocalTaxes

  def download
    move_to_trash
    file = Hamster.connect_to('https://www.census.gov/econ_getzippedfile/?programCode=QTAX') do |response|
      response.headers[:content_type].match?(/stream/)
    end.body
    Zip::File.open_buffer(file) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name.include? 'csv'
        Zlib::GzipReader.open(peon.put(file: "#{FILE_NAME}", content: entry.get_input_stream.read), &:read)
      end
    rescue => e
      message = <<~MSG
              !!! --- ERROR in #86 quarterly_summary_of_state_and_local_taxes Problem with download--- !!!
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
    data = parts.find { |el| el.include?("per_idx,cat_idx,dt_idx,geo_idx,is_adj,val") }
    result = get_main_data(data.split('val').last.strip)
    get_time_periods(parts[3].split("per_name\r\n").last, result.last[:per_idx])
    date_part = parts.find { |el| el.include?("DATA UPDATED ON") }.split(', ').last
    report_date = Date.strptime(date_part, '%d-%b-%y')

    result.each do |h|
      h[:data_source_url] = 'https://www.census.gov/econ_datasets/'
      h[:scrape_frequency] = 'quarterly'
      h[:created_by] = 'Yunus Ganiyev'
      h[:report_date] = report_date
      h[:last_scrape_date] = Time.now
      h[:next_scrape_date] = Time.now + 3.month
      h[:expected_scrape_frequency] = 'quarterly'
      h[:dataset_name_prefix] = 'quarterly_summary_of_state_and_local_taxes'
      h[:scrape_status] = 'live'
      h[:pl_gather_task_id] = 7_596
      h[:created_date] = Time.now
    end
    fill_main_data(result)
  end

  private

  def get_time_periods(file, last_per_idx)
    periods = []
    file.each_line { |line| periods << line.chomp.split(',') }
    time_period = periods.to_h.transform_keys(&:to_i)

    start_per_idx = TIME_PERIODS.last[:per_idx] + 1
    range = start_per_idx..last_per_idx
    selected_time_periods = time_period.select { |key| range.include?(key) }.sort
    selected_time_periods.each { |per_idx, per_name| fill_time_periods(per_idx, per_name.gsub('-', '')) }
  end

  def fill_time_periods(per_idx, per_name)
    h = {
      data_source_url: 'https://www.census.gov/econ_datasets/',
      per_idx: per_idx,
      per_name: per_name,
      scrape_frequency: 'quarterly',
      created_by: 'Yunus Ganiyev',
      created_date: Time.now
    }
    TIME_PERIODS.insert(h)
  end

  def get_main_data(file)
    keys = %w[per_idx cat_idx dt_idx geo_idx is_adj val]

    data = []
    file.split("\r\n").each do |line|
      vals = line.strip.split(',')
      data << vals[0..-2].map(&:to_i) + [vals.last.to_f]
    end
    result = data.map { |n| Hash[keys.map(&:to_sym).zip(n)] }
    if MAIN_DATA.last.nil?
      result.sort_by! { |k| [k[:per_idx], k[:cat_idx], k[:dt_idx]] }
    else
      prev_period = TIME_PERIODS.last[:per_idx]
      result = result.select { |el| el[:per_idx] > prev_period }
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
