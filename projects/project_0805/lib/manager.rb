# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester

  MAIN_URL = 'https://hr.umich.edu/working-u-m/management-administration/hr-reports-data-services/hr-data-requests-standard-reports'

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id
    @salary_pdf_folder = "Salary_Pdfs"
  end

  def download
    main_response = scraper.fetch_page(MAIN_URL)
    parsed_main = parser.parse_html(main_response.body)
    pdf_links_array = parser.get_pdf_links(parsed_main)
    pdf_links_array.each do |pdf_link|
      file_name = pdf_link["title"].downcase.split.join("_").gsub("/","_").gsub("(pdf)", "").gsub(" ","")
      file_link = pdf_link["link"]
      save_file(main_response, file_name, salary_pdf_folder)
    end
    logger.info "Download Done"
  end

  def store
    saved_files = Dir[("#{storehouse}store/#{salary_pdf_folder}/*pdf")]
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      next unless file.include?("2019")
      logger.info "Processing file #{file}"
      reader = PDF::Reader.new(file)
      pdf_pages = reader.pages
      data_array = parser.pdf_data_parser(pdf_pages, run_id)
      keeper.flush(data_array)
    end
    keeper.finish
    logger.info "All Files Data Inserted"
  end

  private 

  attr_accessor :keeper, :scraper, :run_id, :parser, :salary_pdf_folder

  def save_file(response, file_name, folder)
    peon.put content: response.body, file: file_name, subfolder: folder
  end
end
