require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def download
    scraper = Scraper.new
    main_page = scraper.main_page
    save_file("#{keeper.run_id}", main_page.body, "main_page")
    cvs_link = parser.main_page(main_page.body)
    file_name = cvs_link[0].split("/")[-1]
    scraper.csv_downloading(cvs_link[0], "#{keeper.run_id}", file_name)
  end

  def store
    main_page_file = peon.give(subfolder: "#{keeper.run_id}", file: "main_page")
    cvs_link = parser.main_page(main_page_file)
    file_name = cvs_link[0].split("/")[-1]
    file = Dir["#{storehouse}store/#{keeper.run_id}/csv/#{file_name}"]
    csv_data_array = parser.csv_file_reading(file, cvs_link, keeper.run_id ,cvs_link[1])
    unless csv_data_array.empty?
      csv_data_array.each_slice(5000){|data| keeper.insert_records(data)}
    end
  end

  private
  attr_accessor :keeper, :parser

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

end
