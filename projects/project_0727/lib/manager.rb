require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'
require 'zip'

class Manager < Hamster::Scraper
  BASE_URL = "https://open.ga.gov"
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    all_download_page = "https://www.open.ga.gov/download.html"
    response, status = @scraper.get(all_download_page)
    export_all_data_a_tags = @parser.get_all_url_from_page(response.body)
    export_all_data_a_tags.each do |a_tag|
      zip_export_url = @parser.extract_url(a_tag)
      file_name = zip_export_url.split("/")&.last
      @scraper.download_zip_file(BASE_URL + "/#{zip_export_url}", file_name)
    end
  end

  def store
    @all_files = peon.list()
    @all_files.each do |file_name|
      list_of_hashes = parse_csv(file_name)
      @keeper.store(list_of_hashes)
    end
    peon.throw_temps
    @keeper.finish
  end

  def parse_csv(file_name)
    list_of_hashes = []
    Zip::File.open("#{storehouse}store/#{file_name}") do |zipfile|
      zipfile.each do |file|
        file_path = "#{storehouse}trash/#{file.name}"
        zipfile.extract(file,file_path) unless File.exist?(file_path)
        list_of_hashes = @parser.read_csv(file_path)
      end
    end
    list_of_hashes
  end
end
