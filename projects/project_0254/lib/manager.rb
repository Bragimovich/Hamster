require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    main_page = scraper.main_page_get()
    cookie_value = main_page.headers['set-cookie']
    link = parser.get_link(main_page)
    data = scraper.download_file(cookie_value,link)
    save_zip(data.body,"salaries-#{Date.today.to_s}")
  end

  def store
    file_list = peon.list(subfolder: "#{keeper.run_id}/")
    unless file_list.empty?
      file_name = file_list.first
      file = Dir["#{storehouse}store/#{keeper.run_id}/#{file_name}"]
      data_array = parser.get_data(file,keeper.run_id,file_name)
      keeper.insert_records(data_array)
      keeper.finish
    end
  end

  private

  attr_accessor :parser , :scraper ,:keeper

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.csv"
    File.open(zip_storage_path, "a") do |f|
      f.write(content)
    end
  end

end
