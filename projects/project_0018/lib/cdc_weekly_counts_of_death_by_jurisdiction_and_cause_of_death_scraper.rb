require 'net/http'
require 'open-uri'
require 'fileutils'
require 'csv'

require_relative './database_manager'
require_relative '../models/cdc_weekly_counts_of_death_by_jurisdiction_and_cause_of_death'
require_relative './main_logger'

class  CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeathScraper < Hamster::Harvester
  CREATED_BY = 'Sergii Butrymenko'
  SOURCE_FILE = 'Weekly_Counts_of_Death_by_Jurisdiction_and_Select_Causes_of_Death.csv'
  # SOURCE_FILE = 'Weekly_counts_of_death_by_jurisdiction_and_cause_of_death.csv'
  CSV_HEADERS = ['﻿Jurisdiction',
                 'Week Ending Date',
                 'State Abbreviation',
                 'Year',
                 'Week',
                 'Cause Group',
                 'Number of Deaths',
                 'Cause Subgroup',
                 'Time Period',
                 'Suppress',
                 'Note',
                 'Average Number of Deaths in Time Period',
                 'Difference from 2015-2019 to 2020',
                 'Percent Difference from 2015-2019 to 2020',
                 'Type',
  ]

  def initialize
    super
    @url = 'https://data.cdc.gov/api/views/u6jv-9ijr/rows.csv?accessType=DOWNLOAD&bom=true&format=true'
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
      puts "LAST SCRAPED: #{last_scraped}"
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

    # csv = CSV.parse(File.read(@file_path), headers: true, converters: [:date, :numeric, :comma_numbers])
    headers = CSV.foreach(@file_path, headers: true, converters: [:date, :numeric]).first.headers
    # puts headers
    unless check_csv_headers(headers)
      MainLogger.logger.error('Headers in source CSV-file were changed. Code fixes should be made before proceeding.')
      @logger.error('Headers in source CSV-file were changed. Code fixes should be made before proceeding.')
      exit 1
    end

    total_rows = 0
    skipped_rows = 0
    added_rows = 0
    updated_rows = 0

    CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.where(in_csv: 1).update_all(in_csv: 0)

    run_id = get_max_run_id.nil? ? 1 : get_max_run_id + 1

    CSV.foreach(@file_path, headers: true, converters: [:date, :numeric]) do |row|
      # puts JSON.pretty_generate(row)
      t = CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.new
      total_rows += 1
      t.jurisdiction = row[CSV_HEADERS[0]]
      t.week_ending_date = Date.strptime(row[CSV_HEADERS[1]], '%m/%d/%Y')
      t.state_abbreviation = row[CSV_HEADERS[2]]
      t.year  = row[CSV_HEADERS[3]]
      t.week  = row[CSV_HEADERS[4]]
      t.cause_group  = row[CSV_HEADERS[5]]

      t.number_of_deaths =  row[CSV_HEADERS[6]].nil? ? '' : row[CSV_HEADERS[6]].to_s.gsub(',', '')
      t.cause_subgroup =  row[CSV_HEADERS[7]]
      t.time_period =  row[CSV_HEADERS[8]]
      t.suppress =  row[CSV_HEADERS[9]]
      t.note =  row[CSV_HEADERS[10]]
      t.avg_num_of_deaths_in_time_period =  row[CSV_HEADERS[11]].nil? ? '' : row[CSV_HEADERS[11]].to_s.gsub(',', '')
      t.dif_from_2015_2019_to_2020 =  row[CSV_HEADERS[12]].nil? ? '' : row[CSV_HEADERS[12]].to_s.gsub(',', '')
      t.pct_dif_from_2015_2019_to_2020 =  row[CSV_HEADERS[13]].nil? ? '' : row[CSV_HEADERS[13]].to_s.gsub(',', '')
      t.data_type =  row[CSV_HEADERS[14]]

      t.data_source_url = @url
      t.created_by = CREATED_BY
      t.last_scrape_date = Date.today
      t.next_scrape_date = Date.today + 7
      t.expected_scrape_frequency = 'weekly'
      t.dataset_name_prefix = 'cdc_weekly_counts_of_death_by_jurisdiction_and_cause_of_death'
      t.scrape_status = 'live'
      t.pl_gather_task_id = nil
      t.run_id = run_id
      t.in_csv = 1

      db_row = CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.find_by(week_ending_date: t.week_ending_date,
                                                                           jurisdiction: t.jurisdiction,
                                                                           cause_group: t.cause_group,
                                                                           cause_subgroup: t.cause_subgroup,
                                                                           data_type: t.data_type,
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
    deleted_rows = CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.where(in_csv: 0, deleted_at: nil).count
    CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.where(in_csv: 0, deleted_at: nil).update_all(deleted_at: Date.today)

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
    CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.maximum(:last_scrape_date)
  end

  def get_max_run_id
    CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath.maximum(:run_id)
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
      MainLogger.logger.warn("Source file name was changed from '#{SOURCE_FILE}' to '#{file_name}'.")
      @logger.warn("Source file name was changed from '#{SOURCE_FILE}' to '#{file_name}'.")
      return 'filename_changed'
    end
    return 'download'
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
    new_row.jurisdiction == row.jurisdiction &&
    new_row.week_ending_date == row.week_ending_date &&
    # new_row.state_abbreviation == row.state_abbreviation &&
    # new_row.year == row.year &&
    # new_row.week == row.week &&
    new_row.cause_group == row.cause_group &&
    new_row.number_of_deaths == row.number_of_deaths &&
    new_row.cause_subgroup == row.cause_subgroup &&
    new_row.time_period == row.time_period &&
    new_row.suppress == row.suppress &&
    new_row.note == row.note &&
    new_row.avg_num_of_deaths_in_time_period == row.avg_num_of_deaths_in_time_period &&
    new_row.dif_from_2015_2019_to_2020 == row.dif_from_2015_2019_to_2020 &&
    new_row.pct_dif_from_2015_2019_to_2020 == row.pct_dif_from_2015_2019_to_2020 &&
    new_row.data_type == row.data_type
  end
end
