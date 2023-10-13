require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    @run_id = keeper.run_id
    @sub_folder = "RunID_#{run_id}_#{Date.today.year}"
  end

  def download
    response = scraper.main_page
    save_file(response.body, Date.today.year.to_s, sub_folder)
  end

  def store
    hash_array = []
    already_inserted_links = @keeper.fetch_db_inserted_links
    downloaded_file = peon.list(subfolder: sub_folder) rescue []
    file_response = peon.give(subfolder: sub_folder, file: downloaded_file[0])
    response = parser.fetch_page(file_response)
    year_response = parser.year_response(response)
    pdf_links = parser.fetch_pdf_links(year_response)
    pdf_links.each do |pdf|
      next if already_inserted_links.include? pdf

      lines = scraper.pdf_reader(pdf)
      hash_array << parser.parse_data(lines, pdf, run_id)
    end
    keeper.insert_records(hash_array) unless hash_array.empty?
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper, :sub_folder, :run_id

  def save_file(body, file_name, sub_folder)
    peon.put content: body, file: file_name, subfolder: sub_folder
  end
end
