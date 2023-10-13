# frozen_string_literal: true

require 'roo'
require 'roo-xls'
require 'csv'
require_relative '../models/il_prison_population_data_scrape'
require_relative '../models/il_prison_population_data_scrape_runs'

class PrisonScraper < Hamster::Scraper
  URL = 'https://idoc.illinois.gov/reportsandstatistics/prison-population-data-sets.html'
  SUBFOLDER = 'il_prison_population_data_scrape/'
  COLUMN_COUNT = 21
  SCRAPE_NAME = "`#82 il_prison_population_data_scrape`"

  def start
    download
  rescue StandardError => e
  p e.full_message
    Hamster.report(to: 'yunus.ganiyev', message: "Project # 0082: Error - ```#{e.full_message}```")
  end

  def download
    IlPrisonPopulationDataScrapeRuns.create(status: 'started')

    filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    main_page = connect_to(URL, proxy_filter: filter)&.body
    @document = Nokogiri::HTML(main_page)
    parent = @document.at('div#text-d44718848f li')
    latest_link = latest_link(parent)
    period = get_period(parent)
    return if period_already_exists?(period)

    doc = connect_to(latest_link, proxy_filter: filter)&.body

    save_xls(doc, period)
    convert_to_csv(period)

    load_data_to_temp_table(period)
    migrate_data_from_temp_table
    truncate_temp_table

    IlPrisonPopulationDataScrapeRuns.create(status: 'finished')
  end

  def period_already_exists?(period)
    if IlPrisonPopulationDataScrape.where(period: period).any?
      Hamster.report(to: 'yunus.ganiyev', message: "#{period} already exists in the #{SCRAPE_NAME}")
      IlPrisonPopulationDataScrapeRuns.create(status: 'finished')
      true
    else
      message = "#{period} is being added to db15.il_prison_population_date_scrape table from #{SCRAPE_NAME}"
      Hamster.report(to: 'yunus.ganiyev', message: message)
      false
    end
  end

  def get_period(parent)
    date = parent.at('a').text.gsub('Prison Population on ', '').gsub(' Data Set', '')
    Date.strptime(date, '%m-%d-%y').strftime('%Y-%m-%d')
  end

  def latest_link(parent)
    'https://idoc.illinois.gov' + parent.at('a')['href']
  end

  def truncate_temp_table
    @client = Mysql2::Client.new(Storage[host: :db15, db: :hle_data].except(:adapter).merge(symbolize_keys: true))

    query = <<~SQL
      TRUNCATE il_prison_population_data_scrape_temp;  
    SQL

    @client.query(query)
    @client.close
  end

  def migrate_data_from_temp_table
    @client = Mysql2::Client.new(Storage[host: :db15, db: :hle_data].except(:adapter).merge(symbolize_keys: true))

    query = <<~SQL
      INSERT INTO il_prison_population_data_scrape
      (data_source_url, Idoc, name, date_of_birth, sex, race, veteran_status, current_admission_date, admission_type, parent_institution, projected_mandatory_supervised_release_date, projected_discharged_date, custody_date, sentenced_date, crime_class, holding_offense, holding_offense_category, offense_type, sentence_years, sentence_month, truth_in_sentencing, sentecning_county, period, created_by, created_date, broken_date_of_birth, broken_current_admission_date, broken_projected_mandatory_supervised_release_date, broken_projected_discharged_date, broken_custody_date, broken_sentenced_date)
      SELECT
       data_source_url, idoc, name, date_of_birth, sex, race, veteran_status, current_admission_date, admission_type, parent_institution, projected_mandatory_supervised_release_date, projected_discharged_date, custody_date, sentenced_date, crime_class, holding_offense, holding_offense_category, offense_type, sentence_years, sentence_month, truth_in_sentencing, sentecning_county, period, created_by, created_date, broken_date_of_birth, broken_current_admission_date, broken_projected_mandatory_supervised_release_date, broken_projected_discharged_date, broken_custody_date, broken_sentenced_date
      FROM il_prison_population_data_scrape_temp;
    SQL

    @client.query(query)
    @client.close
  end

  def load_data_to_temp_table(period)
    @client = Mysql2::Client.new(Storage[host: :db15, db: :hle_data]
                                   .except(:adapter)
                                   .merge(symbolize_keys: true, local_infile: true))
    output_path =  "#{storehouse}store/#{period}.csv"

    query = <<~SQL
      LOAD DATA LOCAL INFILE '#{output_path}' INTO TABLE il_prison_population_data_scrape_temp
      FIELDS TERMINATED BY ','
      OPTIONALLY ENCLOSED BY '"'
      LINES TERMINATED BY '\n'
      IGNORE 6 LINES
      (`idoc`, `name`, date_of_birth, `sex`, `race`, `veteran_status`, current_admission_date, `admission_type`,
       `parent_institution`, projected_mandatory_supervised_release_date, `projected_discharged_date`, `custody_date`,
       `sentenced_date`, `crime_class`, `holding_offense`, `holding_offense_category`, `offense_type`, `sentence_years`,
       `sentence_month`, `truth_in_sentencing`, `sentecning_county`)
    SQL
    @client.query(query)

    mid_query_0 = <<~SQL
      SET sql_mode=(SELECT REPLACE(@@sql_mode,"NO_ZERO_DATE", ""));
    SQL

    mid_query_1 = <<~SQL
      UPDATE il_prison_population_data_scrape_temp
      SET date_of_birth = NULL
      WHERE date_of_birth = '0000-00-00';
    SQL

    mid_query_2 = <<~SQL
      UPDATE il_prison_population_data_scrape_temp
      SET current_admission_date = NULL
      WHERE current_admission_date = '0000-00-00';
    SQL

    mid_query_3 = <<~SQL
      UPDATE il_prison_population_data_scrape_temp
      SET projected_mandatory_supervised_release_date = NULL
      WHERE projected_mandatory_supervised_release_date = '0000-00-00';
    SQL

    mid_query_4 = <<~SQL
      UPDATE il_prison_population_data_scrape_temp
      SET projected_discharged_date = NULL
      WHERE projected_discharged_date = '0000-00-00';
    SQL

    mid_query_5 = <<~SQL
      UPDATE il_prison_population_data_scrape_temp
      SET custody_date = NULL
      WHERE custody_date = '0000-00-00';
    SQL

    mid_query_6 = <<~SQL
      UPDATE il_prison_population_data_scrape_temp
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
      UPDATE il_prison_population_data_scrape_temp
      SET data_source_url = 'https://idoc.illinois.gov/reportsandstatistics/prison-population-data-sets.html',
      created_by = 'Yunus Ganiyev',
      created_date = updated_at,
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
