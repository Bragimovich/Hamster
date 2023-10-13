# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  URL = 'https://isp.illinois.gov/Sor/DownloadCSV'
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end

  def download
    scraper = Scraper.new
    subfolder = "/#{keeper.run_id}"
    csv_file = scraper.get_csv_file(URL)
    save_file(csv_file.body, 'Sex_Offender_Registry', subfolder)
  end

  def store
    db_processed_md5 = keeper.fetch_already_inserted_md5
    db_crime_record = keeper.fetch_crime_code
    csv_file = peon.give(subfolder: "/#{keeper.run_id}", file: 'Sex_Offender_Registry')
    all_data = parser.get_csv_data(csv_file)
    crime_details_local = parser.get_crimes_data(db_crime_record, all_data)
    keeper.save_crimes_details(crime_details_local) unless crime_details_local.empty?
    crimes_details = keeper.fetch_all_crime_details
    all_data.each_with_index do |row, ind|
      data_hash, = parser.get_parsed_hash(row, ind, keeper.run_id)
      if db_processed_md5.include? data_hash[:md5_hash]
        db_processed_md5.delete data_hash[:md5_hash]
        next
      end
      keeper.save_records(data_hash)
      sex_offender_id = keeper.last_inserted_id
      all_crimes = parser.fetch_crimes(row, sex_offender_id, crimes_details)
      keeper.save_crimes(all_crimes)
    end
    keeper.mark_deleted(db_processed_md5)
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
