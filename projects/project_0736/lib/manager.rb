require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id.to_s
  end

  def download
    (2011..(Date.today.year)).each do |year|
      main_page = scraper.fetch_main_page
      cookie = main_page.headers['set-cookie']
      inner_page = scraper.get_year_page(cookie, year)
      csv_file = scraper.get_csv(cookie)
      save_csv(csv_file.body, year.to_s)
    end
    store
  end

  def store
    all_files  = Dir["#{storehouse}store/#{run_id}/*.csv"]
    all_files.each do |file|
      csv_hashes_array = parser.get_data(file, run_id)
      keeper.insert_data(csv_hashes_array)
    end
    keeper.mark_records_delete
    keeper.finish
  end

  private

  def save_csv(csv, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{run_id}"
    csv_storage_path = "#{storehouse}store/#{run_id}/#{file_name}.csv"
    File.open(csv_storage_path, "wb") do |f|
      f.write(csv)
    end
  end

  attr_accessor :keeper, :parser, :scraper, :run_id
end
