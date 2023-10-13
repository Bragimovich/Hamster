# frozen_string_literal: true

require 'zip'
require_relative '../models/quarterly_survey_of_public_pensions_data'
require_relative '../models/quarterly_survey_of_public_pensions_time_period'
require_relative '../models/quarterly_survey_of_public_pensions_categories'
require_relative '../models/quarterly_survey_of_public_pensions_data_types'

class Scraper < Hamster::Scraper

  FILE_NAME = Time.now.strftime('%Y-%m').gsub('-', '_')
  TIME_PERIODS = QuarterlySurveyOfPublicPensionsTimePeriod
  MAIN_DATA = QuarterlySurveyOfPublicPersonsData
  CATEGORIES = QuarterlySurveyOfPublicPersonsCategory
  DATA_TYPES = QuarterlySurveyOfPublicPersonsDataType

  def download
    move_to_trash
    file = Hamster.connect_to('https://www.census.gov/econ_getzippedfile/?programCode=QPR') do |response|
      response.headers[:content_type].match?(/stream/)
    end.body
    Zip::File.open_buffer(file) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name.include? 'csv'
        Zlib::GzipReader.open(peon.put(file: "#{FILE_NAME}", content: entry.get_input_stream.read), &:read)
      end
    rescue => e
      message = <<~MSG
              !!! --- ERROR in #87 quarterly_survey_of_public_pensions Problem with download--- !!!
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
    get_categories(parts[0].split("\r\n"))
    get_data_types(parts[1].split("\r\n"))
    get_time_periods(parts[3].split("per_name\r\n").last)
    result = get_main_data(parts[5].split('val').last.strip)
    report_date = Date.strptime(parts[4].split(', ').last, '%d-%b-%y')

    result.each do |h|
      h[:data_source_url] = 'https://www.census.gov/econ_datasets/'
      h[:scrape_frequency] = 'quarterly'
      h[:created_by] = 'Yunus Ganiyev'
      h[:report_date] = report_date
      h[:last_scrape_date] = Time.now
      h[:next_scrape_date] = Time.now + 3.month
      h[:expected_scrape_frequency] = 'quarterly'
      h[:dataset_name_prefix] = 'quarterly_survey_of_public_pensions'
      h[:scrape_status] = 'live'
      h[:pl_gather_task_id] = 7_596
      h[:created_date] = Time.now
    end

    fill_main_data(result)
  end

  private

  def get_categories(file)
    file[2..-1].each do |el|
      if el.to_i > CATEGORIES.order("cat_idx desc").first[:cat_idx]
        fill_categories(el)
      else
        cat_el = el.split(',')
        category = CATEGORIES.where('cat_idx': cat_el[0], deleted: 0)

        next if category.pluck('cat_desc').first == cat_el[2]

        category.first.deleted = 1
        category.first.save!
        fill_categories(el)
      end
    end
  end

  def fill_categories(category)
    cat_idx, cat_code, cat_desc, cat_indent = category.split(',')

    h = {
      data_source_url: 'https://www.census.gov/econ_datasets/',
      cat_idx: cat_idx,
      cat_code: cat_code,
      cat_desc: cat_desc,
      cat_indent: cat_indent,
      scrape_frequency: 'quarterly',
      created_by: 'Yunus Ganiyev',
      created_date: Time.now
    }
    CATEGORIES.insert(h)
  end

  def get_data_types(file)
    max_current_data_type_id = DATA_TYPES.last[:dt_idx]

    if file.last.to_i > max_current_data_type_id
      file = file.select { |el| el[0..3].to_i > max_current_data_type_id }
      file.each do |data_type|
        fill_data_types(data_type)
      end
    end

  end

  def fill_data_types(data_type)
    dt_idx, dt_code, dt_desc, dt_unit = data_type.split(',')

    h = {
      data_source_url: 'https://www.census.gov/econ_datasets/',
      dt_idx: dt_idx,
      dt_code: dt_code,
      dt_desc: dt_desc,
      dt_unit: dt_unit,
      scrape_frequency: 'quarterly',
      created_by: 'Yunus Ganiyev',
      created_date: Time.now
    }
    DATA_TYPES.insert(h)
  end

  def get_time_periods(file)
    time_period = []
    file.each_line { |line| time_period << line.chomp }
    per_idx, per_name = time_period.last.split(',')
    last_per_idx = TIME_PERIODS.last[:per_idx]
    per_idx = per_idx.to_i
    if per_idx - last_per_idx > 1
      message =
        "!!! --- `ERROR in #87 quarterly_survey_of_public_pensions`\n
It looks like an iteration has been skipped. Last per_idx = *`#{per_idx}`* , current per_idx = *`#{last_per_idx}`* --- !!!"
      Hamster.report(to: 'Yunus Ganiyev', message: message)
      raise
    end
    fill_time_periods(per_idx, per_name.gsub('-', '')) if per_idx > last_per_idx
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
