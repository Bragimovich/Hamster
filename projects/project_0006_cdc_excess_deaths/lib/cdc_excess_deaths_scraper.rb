# require 'nokogiri'
require 'net/http'
require 'open-uri'
# require 'zlib'
require 'fileutils'
require 'csv'

require_relative './database_manager'
require_relative '../models/cdc_excess_death'
require_relative './main_logger'

class  CDCExcessDeathsScraper < Hamster::Harvester
  CREATED_BY = 'Sergii Butrymenko'
  SOURCE_FILE = 'Excess_Deaths_Associated_with_COVID-19.csv'
  CSV_HEADERS = ['﻿Week Ending Date',
                  'State',
                  'Observed Number',
                  'Upper Bound Threshold',
                  'Exceeds Threshold',
                  'Average Expected Count',
                  'Excess Estimate',
                  'Total Excess Estimate',
                  'Percent Excess Estimate',
                  # 'Excess Lower Estimate',
                  # 'Excess Higher Estimate',
                  'Year',
                  # 'Total Excess Lower Estimate in 2020',
                  # 'Total Excess Higher Estimate in 2020',
                  # 'Percent Excess Lower Estimate',
                  # 'Percent Excess Higher Estimate',
                  'Type',
                  'Outcome',
                  'Suppress',
                  'Note',
  ]

  def initialize
    super
    @url = 'https://data.cdc.gov/api/views/xkkf-xrst/rows.csv?accessType=DOWNLOAD&bom=true&format=true'
    @file_path = storehouse + 'store/source_data.csv'
    @trash_path = @file_path.sub('store/source_data.csv', "trash/source_data_#{Date.today.to_s}.csv")
    FileUtils.mkdir_p storehouse + 'log/'
    @logger = Logger.new(storehouse + 'log/' + "scraping_#{Date.today.to_s}.log", 'monthly', 50 * 1024 * 1024)
  end

  def download_csv_file
    # Dir.mkdir(storehouse) unless File.directory?(storehouse)
    puts 'Starting download'
    uri = URI(@url)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      last_scraped = get_last_scraped
      last_scraped = Date.new(2020,1,1) if last_scraped.nil?
      http.request(request) do |response|
        file_status = check_response(response, last_scraped)
        return file_status unless file_status == 'download'
        File.open(@file_path, 'w') do |file|
          response.read_body do |chunk|
            file.write(chunk)
          end
        end
      end
    end
    MainLogger.logger.info('Source file downloaded successfully.')
    @logger.info('Source file downloaded successfully.')
    'downloaded'
  end

  def parse_csv_file
    unless File.file?(@file_path)
      MainLogger.logger.error("Downloaded file not found in path #{@file_path}")
      @logger.error("Downloaded file not found in path #{@file_path}")
      exit 1
    end
    MainLogger.logger.info('Parsing process started.')
    @logger.info('Parsing process started.')

    # CSV::Converters[:comma_numbers] = ->(s) {(s =~ /^\d+,/) ? (s.gsub(',','').to_f) : s}

    csv = CSV.parse(File.read(@file_path), headers: true, converters: [:date, :numeric])
    unless check_csv_headers(csv.headers)
      MainLogger.logger.error('Headers in source CSV-file were changed. Code fixes should be made before proceeding.')
      @logger.error('Headers in source CSV-file were changed. Code fixes should be made before proceeding.')
      exit 1
    end

    total_rows = 0
    skipped_rows = 0
    added_rows = 0
    updated_rows = 0

    CdcExcessDeath.where(in_csv: 1).update_all(in_csv: 0)

    run_id = get_max_run_id.nil? ? 1 : get_max_run_id + 1

    csv.each do |row|
      # puts JSON.pretty_generate(row.to_hash)
      t = CdcExcessDeath.new
      total_rows += 1
      t.week_ending_date = row[CSV_HEADERS[0]]
      t.state = row[CSV_HEADERS[1]]
      t.observed_number = row[CSV_HEADERS[2]].nil? ? '' : row[CSV_HEADERS[2]].to_s.gsub(',', '')
      t.upper_bound_threshold = row[CSV_HEADERS[3]].nil? ? '' : row[CSV_HEADERS[3]].to_s.gsub(',', '')
      t.exceeds_threshold = row[CSV_HEADERS[4]]
      t.average_expected_count = row[CSV_HEADERS[5]].nil? ? '' : row[CSV_HEADERS[5]].to_s.gsub(',', '')
      t.excess_estimate = row[CSV_HEADERS[6]].nil? ? '' : row[CSV_HEADERS[6]].to_s.gsub(',', '')
      t.total_excess_estimate = row[CSV_HEADERS[7]].nil? ? '' : row[CSV_HEADERS[7]].to_s.gsub(',', '')
      t.percent_excess_estimate = row[CSV_HEADERS[8]].nil? ? '' : row[CSV_HEADERS[8]].to_s.gsub(',', '')
      # t.excess_lower_estimate = row[CSV_HEADERS[6]].nil? ? '' : row[CSV_HEADERS[6]].to_s.gsub(',', '')
      # t.excess_higher_estimate = row[CSV_HEADERS[7]].nil? ? '' : row[CSV_HEADERS[7]].to_s.gsub(',', '')
      t.year = row[CSV_HEADERS[9]]
      # t.total_excess_lower_estimate_in_2020 = row[CSV_HEADERS[9]].nil? ? '' : row[CSV_HEADERS[9]].to_s.gsub(',', '')
      # t.total_excess_higher_estimate_in_2020 = row[CSV_HEADERS[10]].nil? ? '' : row[CSV_HEADERS[10]].to_s.gsub(',', '')
      # t.percent_excess_lower_estimate = row[CSV_HEADERS[11]].nil? ? '' : row[CSV_HEADERS[11]].to_s.gsub(',', '')
      # t.percent_excess_higher_estimate = row[CSV_HEADERS[12]].nil? ? '' : row[CSV_HEADERS[12]].to_s.gsub(',', '')
      t.data_type = row['Type']
      t.outcome = row['Outcome']
      t.suppress = row['Suppress']
      t.note = row['Note']

      t.data_source_url = @url
      t.created_by = CREATED_BY
      t.last_scrape_date = Date.today
      t.next_scrape_date = Date.today + 7
      t.expected_scrape_frequency = 'weekly'
      t.dataset_name_prefix = 'cdc_excess_deaths'
      t.scrape_status = 'live'
      t.pl_gather_task_id = nil
      t.run_id = run_id
      t.in_csv = 1

      db_row = CdcExcessDeath.find_by(week_ending_date: t.week_ending_date,
                                      state: t.state,
                                      data_type: t.data_type,
                                      outcome: t.outcome,
                                      deleted_at: nil)
      begin
        if db_row.blank?
          # puts 'new record'
          DatabaseManager.save_item(t)
          added_rows += 1
        elsif check_record_equality(t, db_row)
          # puts 'existing record'
          db_row.in_csv = 1
          DatabaseManager.save_item(db_row)
          skipped_rows += 1
          next
        else
          # puts 'updated record'
          db_row.deleted_at = Date.today
          DatabaseManager.save_item(db_row)
          DatabaseManager.save_item(t)
          updated_rows += 1
        end
      rescue ActiveRecord::ActiveRecordError => e
        @logger.error(e)
        raise
      end

    end
    deleted_rows = CdcExcessDeath.where(in_csv: 0, deleted_at: nil).count
    CdcExcessDeath.where(in_csv: 0, deleted_at: nil).update_all(deleted_at: Date.today)

    tabs = "\t" * 7

    MainLogger.logger.info("Source csv file has been parsed.\n"\
                                                      "#{tabs}Total rows: #{total_rows}\n"\
                                                      "#{tabs}Added rows: #{added_rows}\n"\
                                                      "#{tabs}Updated rows: #{updated_rows}\n"\
                                                      "#{tabs}Removed rows: #{deleted_rows}\n"\
                                                      "#{tabs}Skipped rows: #{skipped_rows}")
    @logger.info("Source csv file has been parsed.\n"\
                                                      "#{tabs}Total rows: #{total_rows}\n"\
                                                      "#{tabs}Added rows: #{added_rows}\n"\
                                                      "#{tabs}Updated rows: #{updated_rows}\n"\
                                                      "#{tabs}Removed rows: #{deleted_rows}\n"\
                                                      "#{tabs}Skipped rows: #{skipped_rows}")

    move_and_rename_csv_file
    delete_old_csv_files
  end

  private

  def move_and_rename_csv_file
    FileUtils.mv(@file_path, @trash_path)
  end

  def delete_old_csv_files
    Dir.chdir(@trash_path.slice(0, @trash_path.rindex('/')))
    Dir.glob('*.csv').each { |filename| File.delete(filename) if (Time.now - File.ctime(filename))/(24*3600) > 1 }
  end

  def get_last_scraped
    CdcExcessDeath.maximum(:last_scrape_date)
  end

  def get_max_run_id
    CdcExcessDeath.maximum(:run_id)
  end

  def check_response(response, last_scraped)
    case response.code.to_i
    when 200
      MainLogger.logger.info("Return Code #{response.code}. Downloading updated csv file.")
      @logger.info("Return Code #{response.code}. Downloading updated csv file.")
    when 404
      MainLogger.logger.error("Return Code #{response.code}. Source csv file not found!")
      @logger.error("Return Code #{response.code}. Source csv file not found!")
    when 400..499
      MainLogger.logger.error("Return Code #{response.code}. Client error!")
      @logger.error("Return Code #{response.code}. Client error!")
    when 500..599
      MainLogger.logger.error("Return Code #{response.code}. Server error!")
      @logger.error("Return Code #{response.code}. Server error!")
    else
      MainLogger.logger.error("Return Code #{response.code}. Error!")
      @logger.error("Return Code #{response.code}. Error!")
    end
    return 'response_error' unless response.code == '200'
    last_modified = get_source_last_modified(response)
    if last_scraped != nil && last_modified <= last_scraped
      MainLogger.logger.info("No updates found on the source site! Source file last modified data: "\
                                  "#{last_modified}. Dataset last update data: #{last_scraped}.")
      @logger.info("No updates found on the source site! Source file last modified data: "\
                                  "#{last_modified}. Dataset last update data: #{last_scraped}.")
      return 'no_updates'
    end
    file_name = response.to_hash['content-disposition'].join.match(/(?<=filename=).*\.csv/)[0]
    if file_name.empty? || file_name != SOURCE_FILE
      MainLogger.logger.warn("Source file name was changed form '#{SOURCE_FILE}' to #{file_name}.")
      @logger.warn("Source file name was changed form '#{SOURCE_FILE}' to #{file_name}.")
      return 'filename_changed'
    end
    'download'
    rescue StandardError => e
      p e
      p e.backtrace
  end

  def check_csv_headers(csv_headers)
    if csv_headers == CSV_HEADERS
      true
    else
      MainLogger.logger.error("Column names or count of source file were changed.")
      @logger.error("Column names or count of source file were changed.")
      false
    end
  end

  def get_source_last_modified(response)
    Date.parse(response.to_hash['last-modified'].first)
  end

  def check_record_equality(new_row, row)
    new_row.week_ending_date == row.week_ending_date &&
    new_row.state == row.state &&
    new_row.observed_number == row.observed_number &&
    new_row.upper_bound_threshold == row.upper_bound_threshold &&
    new_row.exceeds_threshold == row.exceeds_threshold &&
    new_row.average_expected_count == row.average_expected_count &&
    new_row.excess_estimate == row.excess_estimate &&
    new_row.total_excess_estimate == row.total_excess_estimate &&
    new_row.percent_excess_estimate == row.percent_excess_estimate &&
    # new_row.excess_lower_estimate == row.excess_lower_estimate &&
    # new_row.excess_higher_estimate == row.excess_higher_estimate &&
    new_row.year == row.year &&
    # new_row.total_excess_lower_estimate_in_2020 == row.total_excess_lower_estimate_in_2020 &&
    # new_row.total_excess_higher_estimate_in_2020 == row.total_excess_higher_estimate_in_2020 &&
    # new_row.percent_excess_lower_estimate == row.percent_excess_lower_estimate &&
    # new_row.percent_excess_higher_estimate == row.percent_excess_higher_estimate &&
    new_row.data_type == row.data_type &&
    new_row.outcome == row.outcome &&
    new_row.suppress == row.suppress &&
    new_row.note == row.note
  end
end
