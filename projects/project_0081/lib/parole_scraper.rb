# frozen_string_literal: true

require 'roo'
require 'roo-xls'
require 'csv'
require_relative '../models/il_parole_population_date_scrape'
require_relative '../models/il_parole_population_date_scrape_runs'

class ParoleScraper < Hamster::Scraper
  URL = 'https://idoc.illinois.gov/reportsandstatistics/parole-population-data-sets.html'
  SUBFOLDER = 'il_parole_population_date_scrape/'
  COLUMN_COUNT = 23
  SCRAPE_NAME = "`#81 il_parole_population_date_scrape`"

  def start
    download
  rescue StandardError => e
    p e.full_message
    Hamster.report(to: 'yunus.ganiyev', message: "Project # 0081: Error - ```#{e.full_message}```")
  end

  def download
    IlParolePopulationDateScrapeRuns.create(status: 'started')

    filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.blank? }
    main_page = connect_to(URL, proxy_filter: filter)&.body
    @document = Nokogiri::HTML(main_page)
    parent = @document.at('div#text-c138e20f72 li')
    latest_link = latest_link(parent)
    period = get_period(parent)

    return if period_already_exists?(period)

    doc = connect_to(latest_link, proxy_filter: filter)&.body

    save_xls(doc, period)
    convert_to_csv(period)

    load_data_to_temp_table(period)
    migrate_data_from_temp_table
    truncate_temp_table

    IlParolePopulationDateScrapeRuns.create(status: 'finished')
  end

  private

  def period_already_exists?(period)
    if IlParolePopulationDateScrape.where(period: period).any?
      Hamster.report(to: 'yunus.ganiyev', message: "#{period} already exists in the #{SCRAPE_NAME}")
      IlParolePopulationDateScrapeRuns.create(status: 'finished')
      true
    else
      message = "#{period} is being added to db15.il_parole_population_date_scrape table from #{SCRAPE_NAME}"
      Hamster.report(to: 'yunus.ganiyev', message: message)
      false
    end
  end

  def get_period(parent)
    date = parent.at('a').text.gsub('Parole Population on ', '').gsub(' Data Set', '')
    Date.strptime(date, '%m-%d-%y').strftime('%Y-%m-%d')
  end

  def latest_link(parent)
    'https://idoc.illinois.gov' + parent.at('a')['href']
  end

  def truncate_temp_table
    @client = Mysql2::Client.new(Storage[host: :db15, db: :hle_data].except(:adapter).merge(symbolize_keys: true))

    query = <<~SQL
      TRUNCATE il_parole_population_date_scrape_temp;
    SQL

    @client.query(query)
    @client.close
  end

  def migrate_data_from_temp_table
    @client = Mysql2::Client.new(Storage[host: :db15, db: :hle_data].except(:adapter).merge(symbolize_keys: true))

    query = <<~SQL
      INSERT INTO il_parole_population_date_scrape
      (data_source_url, idoc, name, date_of_birth, sex, race, veteran_status, current_admission_date, admission_type, parent_institution, mandatory_supervised_release_date, projected_discharge_date, custody_date, sentenced_date, crime_class, holding_offense, holding_offense_category, offense_type, sentence_years, sentence_month, truth_in_sentencing, sentencing_county, county_of_residence, residence_zip_code, period, created_by, created_at, updated_at, city, county, state, pl_prod_county_id, pl_prod_city_id, zip_lat, zip_lon)
      SELECT
       data_source_url, idoc, name, date_of_birth, sex, race, veteran_status, current_admission_date, admission_type, parent_institution, mandatory_supervised_release_date, projected_discharge_date, custody_date, sentenced_date, crime_class, holding_offense, holding_offense_category, offense_type, sentence_years, sentence_month, truth_in_sentencing, sentencing_county, county_of_residence, residence_zip_code, period, created_by, created_at, updated_at, city, county, state, pl_prod_county_id, pl_prod_city_id, zip_lat, zip_lon
      FROM il_parole_population_date_scrape_temp;
    SQL

    @client.query(query)
    @client.close
  end

  def load_data_to_temp_table(period)
    @client = Mysql2::Client.new(Storage[host: :db15, db: :hle_data]
                                   .except(:adapter)
                                   .merge(symbolize_keys: true, local_infile: true))
    output_path = "#{storehouse}store/#{period}.csv"

    query = <<~SQL
      LOAD DATA LOCAL INFILE '#{output_path}' INTO TABLE il_parole_population_date_scrape_temp
      FIELDS TERMINATED BY ','
      OPTIONALLY ENCLOSED BY '"'
      LINES TERMINATED BY '\n'
      IGNORE 6 LINES
      (`idoc`, `name`, date_of_birth, `sex`, `race`, `veteran_status`, current_admission_date, `admission_type`,
       `parent_institution`, mandatory_supervised_release_date, projected_discharge_date, custody_date, sentenced_date,
       `crime_class`, `holding_offense`, `holding_offense_category`, `offense_type`, `sentence_years`, `sentence_month`,
       `truth_in_sentencing`, `sentencing_county`, `county_of_residence`, `residence_zip_code`)
    SQL
    @client.query(query)

    mid_query_0 = <<~SQL
      SET sql_mode=(SELECT REPLACE(@@sql_mode,"NO_ZERO_DATE", ""));
    SQL

    mid_query_1 = <<~SQL
      UPDATE il_parole_population_date_scrape_temp
      SET date_of_birth = NULL 
      WHERE date_of_birth = '0000-00-00';
    SQL

    mid_query_2 = <<~SQL
      UPDATE il_parole_population_date_scrape_temp
      SET current_admission_date = NULL
      WHERE current_admission_date = '0000-00-00';
    SQL

    mid_query_3 = <<~SQL
      UPDATE il_parole_population_date_scrape_temp
      SET mandatory_supervised_release_date = NULL
      WHERE mandatory_supervised_release_date = '0000-00-00';
    SQL

    mid_query_4 = <<~SQL
      UPDATE il_parole_population_date_scrape_temp
      SET projected_discharge_date = NULL
      WHERE projected_discharge_date = '0000-00-00';
    SQL

    mid_query_5 = <<~SQL
      UPDATE il_parole_population_date_scrape_temp
      SET custody_date = NULL
      WHERE custody_date = '0000-00-00';
    SQL

    mid_query_6 = <<~SQL
      UPDATE il_parole_population_date_scrape_temp 
      SET sentenced_date = NULL 
      WHERE sentenced_date = '0000-00-00';
    SQL

    @client.query(mid_query_0)
    @client.query(mid_query_1)
    @client.query(mid_query_2)
    @client.query(mid_query_3)
    @client.query(mid_query_4)
    @client.query(mid_query_5)
    @client.query(mid_query_6)

    post_query = <<~SQL
      UPDATE il_parole_population_date_scrape_temp
      SET data_source_url = 'https://idoc.illinois.gov/reportsandstatistics/parole-population-data-sets.html',
      created_by = 'Yunus Ganiyev',
      created_at = updated_at,
      period = '#{period}';
    SQL

    @client.query(post_query)
    @client.close
  end

  def convert_to_csv(period)
    excel = Roo::Excel.new("#{storehouse}store/#{period}.xls")

    if excel.row(6).size != COLUMN_COUNT
      Hamster.report(to: 'yunus.ganiyev', message: "`Error:` Incorrect column number in #{SCRAPE_NAME}")
      raise ColumnCountError << StandardError
    end

    output_path = "#{storehouse}/store/#{period}.csv"
    output = File.open(output_path, 'w')

    1.upto(excel.last_row) do |line|
      output.write CSV.generate_line excel.row(line)
    end
  end

  def save_xls(xls, period)
    peon.move_all_to_trash
    path = "#{storehouse}store/"
    FileUtils.mkdir_p path
    xls_full_name = "#{path}#{period}.xls"
    File.open(xls_full_name, 'w') do |f|
      f.write(xls)
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    3.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end

    response
  end
end
