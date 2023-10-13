require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id.to_s
  end

  def download
    main_page = scraper.get_page('https://sde.ok.gov/documents/2018-01-02/certified-staff-salary-information')
    links = parser.get_links(main_page.body)
    year = 2005
    links.each do |link|
      page = scraper.get_page(link)
      save_file(page.body, year+=1)
    end
    store
  end

  def store
    main_path = "#{storehouse}store/#{run_id}"
    files = peon.list(subfolder: run_id).sort rescue []
    files.each do |file|
      path = "#{main_path}/#{file}"
      data_array = parser.parser(path, run_id)
      keeper.insert_data(data_array) unless data_array.empty?
    end
    keeper.mark_delete
    keeper.finish
  end

  private

  def save_file(file, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{run_id}"
    pdf_storage_path = "#{storehouse}store/#{run_id}/#{file_name}.xlsx"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(file)
    end
  end

  attr_accessor :keeper, :parser, :scraper, :run_id

end
