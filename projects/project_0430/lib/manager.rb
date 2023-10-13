require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = "#{@keeper.run_id}"
  end

  def run
    (keeper.download_status == "finish") ? store : download
  end

  private

  def download
    scraper = Scraper.new
    response = scraper.fetch_main_page
    page = parser.parse_page(response.body)
    db_links = keeper.fetch_db_inserted_links
    links = parser.get_links(page)
    links.each do |link|
      next if db_links.include? link
      file = link.split('/').last
      scraper.file_downloading(link, run_id, file)
    end
    keeper.finish_download
    store
  end

  def store
    all_files = peon.list(subfolder: "#{run_id}")
    all_files.each do |file|
      source_file = Dir["#{storehouse}store/#{run_id}/#{file}"].first
      complete_data = parser.parse_data(source_file)
      data = parser.parse_file(complete_data, run_id, file)
      keeper.insert_records(data)
    end
    keeper.finish
  end

  attr_accessor :parser, :keeper, :run_id
end
