require 'net/http'
require 'open-uri'
require 'fileutils'
require 'csv'

require 'digest'

require_relative './database_manager'
require_relative '../models/cdc_weekly_counts_of_deaths_by_state_and_select_cause'
require_relative './main_logger'

class  CDCWeeklyCountsOfDeathsByStateAndSelectCausesScraper < Hamster::Harvester
  CREATED_BY = 'Sergii Butrymenko'
  # SOURCE_FILE = 'Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2020-2021.csv'
  # SOURCE_FILE = 'Weekly_Provisional_Counts_of_Deaths_by_State_and_Select_Causes__2020-2022.csv'
  SOURCE_FILE = 'Weekly_Provisional_Counts_of_Deaths_by_State_and_Select_Causes__2020-2023.csv'
  CSV_HEADERS = [
      '﻿Data As Of',
      'Jurisdiction of Occurrence',
      # '﻿Jurisdiction of Occurrence',
      'MMWR Year',
      'MMWR Week',
      'Week Ending Date',
      'All Cause',
      'Natural Cause',
      'Septicemia (A40-A41)',
      'Malignant neoplasms (C00-C97)',
      'Diabetes mellitus (E10-E14)',
      'Alzheimer disease (G30)',
      'Influenza and pneumonia (J09-J18)',
      'Chronic lower respiratory diseases (J40-J47)',
      'Other diseases of respiratory system (J00-J06,J30-J39,J67,J70-J98)',
      'Nephritis, nephrotic syndrome and nephrosis (N00-N07,N17-N19,N25-N27)',
      'Symptoms, signs and abnormal clinical and laboratory findings, not elsewhere classified (R00-R99)',
      'Diseases of heart (I00-I09,I11,I13,I20-I51)',
      'Cerebrovascular diseases (I60-I69)',
      'COVID-19 (U071, Multiple Cause of Death)',
      'COVID-19 (U071, Underlying Cause of Death)',
      'flag_allcause',
      'flag_natcause',
      'flag_sept',
      'flag_neopl',
      'flag_diab',
      'flag_alz',
      'flag_inflpn',
      'flag_clrd',
      'flag_otherresp',
      'flag_nephr',
      'flag_otherunk',
      'flag_hd',
      'flag_stroke',
      'flag_cov19mcod',
      'flag_cov19ucod'
  ]

  def initialize
    super
    @url = 'https://data.cdc.gov/api/views/muzy-jte6/rows.csv?accessType=DOWNLOAD&bom=true&format=true'
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
    csv = CSV.parse(File.read(@file_path), headers: true, converters: [:date, :numeric])

    unless check_csv_headers(csv.headers)
      MainLogger.logger.error('Headers in source CSV-file were changed. Code fixes should be made before proceeding.')
      @logger.error('Headers in source CSV-file were changed. Code fixes should be made before proceeding.')
      raise 'Headers in source CSV-file were changed. Code fixes should be made before proceeding.'
    end

    total_rows = 0
    skipped_rows = 0
    added_rows = 0
    updated_rows = 0

    CDCWeeklyCountsOfDeathsByStateAndSelectCause.where(in_csv: 1).update_all(in_csv: 0)

    run_id = get_max_run_id.nil? ? 1 : get_max_run_id + 1

    csv.each do |row|
      # puts JSON.pretty_generate(row.to_hash)
      t = CDCWeeklyCountsOfDeathsByStateAndSelectCause.new
      total_rows += 1
      t.data_source_url = @url
      t.data_as_of = Date.strptime(csv.first[CSV_HEADERS[0]], '%m/%d/%Y')
      # t.data_as_of = row[CSV_HEADERS[0]]
      t.jurisdiction = row[CSV_HEADERS[1]]
      t.mmwr_year =  row[CSV_HEADERS[2]]
      t.mmwr_week =  row[CSV_HEADERS[3]]
      t.week_ending_date  = row[CSV_HEADERS[4]]


      t.allcause =    row[CSV_HEADERS[5]].nil? ? '1-9' : row[CSV_HEADERS[5]].to_s.gsub(',', '')
      t.natcause =    row[CSV_HEADERS[6]].nil? ? '1-9' : row[CSV_HEADERS[6]].to_s.gsub(',', '')
      t.sept =        row[CSV_HEADERS[7]].nil? ? '1-9' : row[CSV_HEADERS[7]].to_s.gsub(',', '')
      t.neopl =       row[CSV_HEADERS[8]].nil? ? '1-9' : row[CSV_HEADERS[8]].to_s.gsub(',', '')
      t.diab =        row[CSV_HEADERS[9]].nil? ? '1-9' : row[CSV_HEADERS[9]].to_s.gsub(',', '')
      t.alz =         row[CSV_HEADERS[10]].nil? ? '1-9' : row[CSV_HEADERS[10]].to_s.gsub(',', '')
      t.inflpn =      row[CSV_HEADERS[11]].nil? ? '1-9' : row[CSV_HEADERS[11]].to_s.gsub(',', '')
      t.clrd =        row[CSV_HEADERS[12]].nil? ? '1-9' : row[CSV_HEADERS[12]].to_s.gsub(',', '')
      t.otherresp =   row[CSV_HEADERS[13]].nil? ? '1-9' : row[CSV_HEADERS[13]].to_s.gsub(',', '')
      t.nephr =       row[CSV_HEADERS[14]].nil? ? '1-9' : row[CSV_HEADERS[14]].to_s.gsub(',', '')
      t.otherunk =    row[CSV_HEADERS[15]].nil? ? '1-9' : row[CSV_HEADERS[15]].to_s.gsub(',', '')
      t.hd =          row[CSV_HEADERS[16]].nil? ? '1-9' : row[CSV_HEADERS[16]].to_s.gsub(',', '')
      t.stroke =      row[CSV_HEADERS[17]].nil? ? '1-9' : row[CSV_HEADERS[17]].to_s.gsub(',', '')
      t.cov19mcod =   row[CSV_HEADERS[18]].nil? ? '1-9' : row[CSV_HEADERS[18]].to_s.gsub(',', '')
      t.cov19ucod =   row[CSV_HEADERS[19]].nil? ? '1-9' : row[CSV_HEADERS[19]].to_s.gsub(',', '')

      # t.allcause = row[CSV_HEADERS[4]]
      # t.natcause = row[CSV_HEADERS[5]]
      # t.sept = row[CSV_HEADERS[6]]
      # t.neopl = row[CSV_HEADERS[7]]
      # t.diab = row[CSV_HEADERS[8]]
      # t.alz = row[CSV_HEADERS[9]]
      # t.inflpn = row[CSV_HEADERS[10]]
      # t.clrd = row[CSV_HEADERS[11]]
      # t.otherresp =row[CSV_HEADERS[12]]
      # t.nephr = row[CSV_HEADERS[13]]
      # t.otherunk = row[CSV_HEADERS[14]]
      # t.hd = row[CSV_HEADERS[15]]
      # t.stroke = row[CSV_HEADERS[16]]
      # t.cov19mcod = row[CSV_HEADERS[17]]
      # t.cov19ucod = row[CSV_HEADERS[18]]
      # t.flag_allcause = row[CSV_HEADERS[19]]
      # t.flag_natcause = row[CSV_HEADERS[20]]
      # t.flag_sept = row[CSV_HEADERS[21]]
      # t.flag_neopl = row[CSV_HEADERS[22]]
      # t.flag_diab = row[CSV_HEADERS[23]]
      # t.flag_alz = row[CSV_HEADERS[24]]
      # t.flag_inflpn = row[CSV_HEADERS[25]]
      # t.flag_clrd = row[CSV_HEADERS[26]]
      # t.flag_otherresp = row[CSV_HEADERS[27]]
      # t.flag_nephr = row[CSV_HEADERS[28]]
      # t.flag_otherunk = row[CSV_HEADERS[29]]
      # t.flag_hd = row[CSV_HEADERS[30]]
      # t.flag_stroke = row[CSV_HEADERS[31]]
      # t.flag_cov19mcod = row[CSV_HEADERS[32]]
      # t.flag_cov19ucod = row[CSV_HEADERS[33]]

      t.created_by = CREATED_BY
      t.last_scrape_date = Date.today
      t.next_scrape_date = Date.today + 7
      t.expected_scrape_frequency = 'weekly'
      t.dataset_name_prefix = 'cdc_weekly_counts_of_deaths_by_state_and_select_causes'
      t.scrape_status = 'live'
      t.pl_gather_task_id = nil
      t.run_id = run_id
      t.in_csv = 1

      db_row = CDCWeeklyCountsOfDeathsByStateAndSelectCause.find_by(week_ending_date: t.week_ending_date,
                                                                    jurisdiction: t.jurisdiction,
                                                                    deleted_at: nil)
      begin
        if db_row.blank?
          # puts 'adding record'
          DatabaseManager.save_item(t)
          added_rows += 1
        elsif check_record_equality(t, db_row)
          # puts 'skipping record'
          db_row.in_csv = 1
          DatabaseManager.save_item(db_row)
          skipped_rows += 1
          next
        else
          # puts 'updating record'
          db_row.deleted_at = Date.today
          DatabaseManager.save_item(db_row)
          DatabaseManager.save_item(t)
          updated_rows += 1
        end
      rescue ActiveRecord::ActiveRecordError => e
        @logger.error(e)
        raise e
      end

    end
    deleted_rows = CDCWeeklyCountsOfDeathsByStateAndSelectCause.where(in_csv: 0, deleted_at: nil).count
    CDCWeeklyCountsOfDeathsByStateAndSelectCause.where(in_csv: 0, deleted_at: nil).update_all(deleted_at: Date.today)

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
    CDCWeeklyCountsOfDeathsByStateAndSelectCause.maximum(:last_scrape_date)
  end

  def get_max_run_id
    CDCWeeklyCountsOfDeathsByStateAndSelectCause.maximum(:run_id)
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
      MainLogger.logger.warn("Source file name was changed form '#{SOURCE_FILE}' to '#{file_name}'.")
      @logger.warn("Source file name was changed form '#{SOURCE_FILE}' to '#{file_name}'.")
      # Hamster::HamsterTools.report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: :warning: Source file name was changed form '#{SOURCE_FILE}' to '#{file_name}'", use: :both)
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
    new_row.jurisdiction == row.jurisdiction &&
    new_row.week_ending_date == row.week_ending_date &&
    new_row.allcause == row.allcause &&
    new_row.natcause == row.natcause &&
    new_row.sept == row.sept &&
    new_row.neopl == row.neopl &&
    new_row.diab == row.diab &&
    new_row.alz == row.alz &&
    new_row.inflpn == row.inflpn &&
    new_row.clrd == row.clrd &&
    new_row.otherresp == row.otherresp &&
    new_row.nephr == row.nephr &&
    new_row.otherunk == row.otherunk &&
    new_row.hd == row.hd &&
    new_row.stroke == row.stroke &&
    new_row.cov19mcod == row.cov19mcod &&
    new_row.cov19ucod == row.cov19ucod
  end
end
