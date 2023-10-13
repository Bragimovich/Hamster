require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @subfolder_path = "#{@keeper.run_id}"
  end

  def download
    main_page_url = "https://salary.app.tn.gov/public/searchsalary"
    agency_name_url = "https://salary.app.tn.gov/salary/api/distinctAgencyNames.json"
    scraper = Scraper.new
    main_page = scraper.fetch_page(main_page_url)
    cookie = main_page.headers['set-cookie']
    agency_data = scraper.fetch_page(agency_name_url)
    agency_name_array = parser.get_agency_name_array(agency_data.body)
    agency_name_array.each do |agency_name|
      json_response = scraper.fetch_api__data(agency_name, cookie)
      save_file(json_response.body, get_file_name(agency_name))
    end
  end

  def store
    inserted_records = keeper.fetch_db_inserted_md5_hash
    agency_lists = peon.give_list(subfolder:subfolder_path)
    agency_lists.each do |agency|
      response = peon.give(subfolder: "#{subfolder_path}", file: agency)
      hash_array, inserted_records = parser.get_data(response, keeper.run_id, inserted_records)
      keeper.insert_records(hash_array) unless hash_array.empty?
    end
    keeper.deleted(inserted_records)
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :subfolder_path

  def save_file(html, file_name)
    peon.put content: html, file: file_name, subfolder: subfolder_path
  end

  def get_file_name(agency_name)
    agency_name.gsub(/&|,| |'/, '') rescue nil
  end

end
