# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require 'google_drive'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id
  end

  def download
    download_nc_raw_data
    logger.info '***'*20, "Scrape - Download Done!", '***'*20
  end
  
  def store
    store_nc_raw_data
    logger.info '***'*20, "Scrape - Store Done!", '***'*20
  end

  private

  attr_accessor :keeper, :parser, :run_id

  def download_nc_raw_data
    logger.info "Downloading..."
    credentials = Google::Auth::UserRefreshCredentials.new(Storage.new.auth)
    session = GoogleDrive::Session.from_credentials(credentials)
    state_folders = session.file_by_id("10MEskbZAyK6cSAA9GLTb5mInEub39BeC")
    state_folders.files.each do |state_folder|
      folder_id = state_folder.id
      folder_name = state_folder.title
      next unless folder_name.include?("North Carolina")
      state_folder.files.each do |file|
        file_id = file.id
        file_name = file.title.split.join("_")
        next unless file_name.match(/[.]\S{1,4}$/i)
        file_path = "#{storehouse}store/#{folder_name}"
        file = session.file_by_id(file_id)
        FileUtils.mkdir_p(file_path)
        logger.info "Downloading #{file_name}"
        unless File.exist?(File.join(file_path, file_name))
          file = file.download_to_file("#{file_path}/#{file_name}") 
        end
        unzip_csv_files(file_path, file_name)
      end
      logger.info "Downloading Done !!!"
    end
  end
  
  def store_nc_raw_data
    state_folders = Dir["#{storehouse}store/*"]
    state_folders.each do |state_file_folder|
      state_file_folder = Dir["#{state_file_folder}/*"]
      state_file_folder.each do |file_folder|
        next if file_folder.match(/[.]\S{1,4}$/i)# or !file_folder.include?("NcVoterFiles") use this to insert large txt file nc_ncvoter

        csv_files = Dir["#{file_folder}/*.csv"]
        logger.info "Found #{csv_files.count} CSVs"
        csv_files.each do |csv_file|
          logger.info "Processing file #{csv_file}"
          parser.get_csv_data(csv_file, run_id)
        end

        xlsx_files = Dir["#{file_folder}/*.xlsx"]
        logger.info "Found #{xlsx_files.count} XLSXs"
        xlsx_files.each do |xlsx_file|
          logger.info "Processing file #{xlsx_file}"
          parser.get_xlsx_data(xlsx_file, run_id)
        end

        txt_files = Dir["#{file_folder}/*.txt"]
        logger.info "Found #{txt_files.count} TXTs"
        txt_files.each do |txt_file|
          file_name = txt_file.split("/").last.split(".txt").first
          logger.info "Processing file #{file_name}"
          parser.get_txt_data(txt_file, run_id, file_name)
        end
        
        keeper.finish
      end
    end
  end

  def unzip_csv_files(zip_file_path, zip_file_name)
    full_path = "#{zip_file_path}/#{zip_file_name}"
    Zip::File.open(full_path) do |zip_file|
      zip_file.each do |entry|
        file_name = entry.name
        entry_path = full_path.gsub(/[.]\S{1,4}$/, "")
        path = FileUtils.mkdir_p(entry_path).first
        next if File.exist?(File.join(path, file_name))
        entry.extract("#{path}/#{file_name}")
      end
    end
  end

end
