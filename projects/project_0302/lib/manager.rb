require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  MAIN_URL = "https://dos.myflorida.com/elections/data-statistics/voter-registration-statistics/voter-registration-reports/"
  def initialize
    super
    @parser = FloridaParser.new
    @keeper = Keeper.new 
  end

  def download
    scraper = Scraper.new
    getting_main_page = scraper.getting_page(MAIN_URL)
    save_page(getting_main_page,"outer_page","#{@keeper.run_id}")
    link = @parser.info_links(getting_main_page.body)
    files_array = peon.give_list(subfolder: "#{@keeper.run_id}")
    appender = "https://files.floridados.gov"
    file_name = Digest::MD5.hexdigest link
    unless files_array.include? link
      getting_inner_page = scraper.getting_page(appender+link)
      save_xlxs(getting_inner_page.body, file_name)
    end
  end

  def store
    getting_main_page = peon.give(subfolder: "#{@keeper.run_id}", file: "outer_page.gz")
    link = @parser.info_links(getting_main_page)
    file_name = Digest::MD5.hexdigest link
    path = "#{storehouse}store/#{@keeper.run_id}/#{file_name}.xlsx"
    data = @parser.excel_data(path,link,@keeper.run_id)
    @keeper.save_record(data)
    @keeper.finish
  end

  private

  def save_xlxs(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{@keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{@keeper.run_id}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
end
