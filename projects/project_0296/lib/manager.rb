require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  MAIN_URL = "https://sos.idaho.gov/elections-division/voter-registration-totals/"
  def initialize
    super
    @parser = IdahoParser.new 
    @keeper = Keeper.new
  end

  def download
    scraper = Scraper.new
    getting_main_page = scraper.getting_page(MAIN_URL)
    save_page(getting_main_page,"outer_page","#{keeper.run_id}")
    links = parser.info_links(getting_main_page.body)
    files_array = peon.give_list(subfolder: "#{keeper.run_id}")
    links.each do |link|
      file_name = Digest::MD5.hexdigest link
      next if files_array.include? link
      url = MAIN_URL.split(".gov").first + (".gov") + link 
      getting_inner_page = scraper.getting_page(url)
      (link.include? "xlsx") ? save_zip(getting_inner_page.body, file_name) : save_page(getting_inner_page, file_name, "#{keeper.run_id}")
    end
  end

  def store
    getting_main_page = peon.give(subfolder: "#{keeper.run_id}", file: "outer_page.gz")
    links = parser.info_links(getting_main_page)
    links.each do |link|
      file_name = Digest::MD5.hexdigest link
      if link.include? "xlsx"
        file_name = file_name
        path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.xlsx"
        data = parser.excel_data(path,link,keeper.run_id)
        keeper.save_record(data)
      else
        file_name = file_name + ".gz"
        inner_page = peon.give(file:file_name, subfolder: "#{keeper.run_id}")
        data = parser.html_data(inner_page,link,keeper.run_id)
        keeper.save_record(data)
      end
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
end
