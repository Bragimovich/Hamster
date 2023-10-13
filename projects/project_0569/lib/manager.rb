require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
  end

  def download
    scraper  = Scraper.new
    main_page = scraper.connect_main
    response = parser.nokogiri_response(main_page.body)
    links = parser.get_links(response)
    links.each do |link|
      next if link.split("-").last.split(".").first.to_i <= 2018
      link_response = scraper.connect_link(link)
      save_xlsx(link_response.body, link.split("-").last.split(".").first)
    end
  end

  def store
    files =  peon.list(subfolder: "Excel_Files")
    files.each do |file|
      data_array_hr = [] 
      data_array_earnings = []
      path = Dir["#{storehouse}store/Excel_Files/#{file}"]
      data_array_hr = parser.get_data(path[0], 1, file.split(".").first, keeper.run_id)
      data_array_earnings = parser.get_data(path[0], 2, file.split(".").first, keeper.run_id)
      keeper.insert_records('hr', data_array_hr) unless data_array_hr.empty?
      keeper.insert_records('earnings', data_array_earnings) unless data_array_earnings.empty?
    end
    keeper.finish
  end
  
  private

  attr_accessor  :parser ,:keeper 

  def save_xlsx(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/Excel_Files"
    zip_storage_path = "#{storehouse}store/Excel_Files/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
