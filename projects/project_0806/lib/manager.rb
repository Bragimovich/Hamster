# frozen_string_literal: true

require_relative "keeper"
require_relative "parser"
require_relative "scraper"
require 'google_drive'
require 'rtesseract'
require 'pdftoimage'

class Manager < Hamster::Harvester

  MAIN_URL = "https://wirepoints.org/school-district-report-cards/district-report-cards/"

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id
    @credentials = Google::Auth::UserRefreshCredentials.new(Storage.new.auth)
    @session = GoogleDrive::Session.from_credentials(credentials)
  end

  def download
    pdf_folders = session.file_by_id("1fp37k1JGw0ch9ZUkleIyB_PoJ0MNPvvf")
    pdf_folders.files.each do |pdf_folder|
      folder_id = pdf_folder.id
      folder_name = pdf_folder.title
      pdf_folder.files.each do |file|
        file_id = file.id
        file_name = file.title.gsub(" ", "_")
        file_path = "#{storehouse}store/#{folder_name}"
        file = session.file_by_id(file_id)
        FileUtils.mkdir_p(file_path)
        unless File.exist?(File.join(file_path, file_name))
          file = file.download_to_file("#{file_path}/#{file_name}") 
        end
      end
    end
    logger.info "Download Done"
  end

  def store
    files_folders = Dir[("#{storehouse}store/*")]
    files_folders.each do |folder|
      logger.info "Processing folder #{folder}"
      saved_files = Dir[("#{folder}/*.pdf")]
      logger.info "Found #{saved_files.count} files"
      saved_files.each do |file|
        next if file.include?("Illinois_Statewide")
        file_name = file.split("#{folder}/").last.split(".pdf").first
        logger.info "Processing file #{file}"
        reader = PDF::Reader.new(file)
        pdf_pages = reader.pages
        data_hash = parser.pdf_data_parser(pdf_pages, file_name, run_id)
        keeper.insert_all_data(data_hash)
        keeper.update_touch_run_id
      end
    end
    keeper.mark_deleted
    keeper.finish
    logger.info "******** Store Done *******"
  end

  private 

  attr_accessor :keeper, :scraper, :run_id, :parser, :credentials, :session

end

