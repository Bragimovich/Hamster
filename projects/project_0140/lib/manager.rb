require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/zip_generator'
require 'zip'

CONNECTION_ERROR_CLASSES = [ActiveRecord::ConnectionNotEstablished,
                            Mysql2::Error::ConnectionError,
                            ActiveRecord::StatementInvalid,
                            ActiveRecord::LockWaitTimeout]

class Manager < Hamster::Harvester
  URL_PREFIX = "https://markets.ft.com/data/search?query="
  URL_SUFFIX = "&country=US&assetClass=Equity"
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper  = Scraper.new
    @subfolder = "#{keeper.run_id}"
  end

  def store
    store_prices
    store_info
    keeper.finish
    tars_to_aws
  end

  def download_equities
    begin
      scraper.safe_connection do
        @start_time = Time.new
        @subfolder = Date.today.to_s.gsub('-', '_')
        already_inserted_equties = keeper.fetch_already_inserted_equties
        seach_arry = ("a".."z").to_a
        seach_arry.append(("aa".."zz").to_a)
        seach_arry.append(("aaa".."zzz").to_a)
        seach_arry = seach_arry.flatten
        seach_arry.each do |letters|
          data_source_url = URL_PREFIX + letters + URL_SUFFIX
          page            = scraper.connect_to(data_source_url)
          equitirs_url    = parser.get_equities_url(page.body)[0] rescue nil
          next if equitirs_url.nil?

          save_file(page, "Letters_"+letters, "equities")
          download_equity_page(equitirs_url, already_inserted_equties)
        end
      end
      end_time = Time.new
      total_time = (end_time - @start_time)/3600
      logger.debug "total time #{total_time} hours"
      Hamster.report(to: 'UD1LWNPEW', message: "#{Time.now} - #140 Downloaded, total time #{total_time}" , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'UD1LWNPEW', message: "#{Time.now} - Files Scraping Failed - #{msg}" , use: :slack)
    end
  end

  def download_price
    begin
      scraper.safe_connection do
        @start_time = Time.new
        already_downloaded_files = get_already_downloaded_files('price')
        links = keeper.fetch_links
        links.each do |link|
          file_name = get_file_name(link)
          next if already_downloaded_files.include? file_name

          price_page = scraper.connect_to(link)
          save_file(price_page, "price_#{file_name}", "price")
        end
      end
      end_time = Time.new
      total_time = (end_time - @start_time)/3600
      logger.debug "total time #{total_time} hours"
      Hamster.report(to: 'UD1LWNPEW', message: "#{Time.now} - #140 Downloaded, total time #{total_time}" , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'UD1LWNPEW', message: "#{Time.now} - Files Scraping Failed - #{msg}" , use: :slack)
    end
  end

  def download_info
    begin
      scraper.safe_connection do
        @start_time = Time.new
        already_downloaded_files = get_already_downloaded_files('info')
        links = keeper.fetch_links.map { |e| e.gsub('summary', 'profile') }
        links.each do |link|
          file_name = get_file_name(link)
          next if already_downloaded_files.include? file_name

          info_page = scraper.connect_to(link)
          save_file(info_page, "info_#{file_name}", "info")
        end
      end
      end_time = Time.new
      total_time = (end_time - @start_time)/3600
      logger.debug "total time #{total_time} hours"
      Hamster.report(to: 'UD1LWNPEW', message: "#{Time.now} - #140 Downloaded, total time #{total_time}" , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'UD1LWNPEW', message: "#{Time.now} - Files Scraping Failed - #{msg}" , use: :slack)
    end
  end

  def store_equities
    @subfolder = peon.list.reject { |e| e.length < 4 }.max
    already_inserted_equties = keeper.fetch_already_inserted_equties
    files = peon.list(subfolder:@subfolder + "/" + "equities").reject { |e| e.exclude?"Letters" }.sort rescue []
    files.each do |file|
      data_array = []
      page = peon.give(file:file, subfolder:@subfolder + "/" + "equities")
      equitirs_url, countries, exchanges = parser.get_equities_url(page)
      data_source_url = URL_PREFIX + file.split(".").first.split("_").last + URL_SUFFIX
      equitirs_url.each_with_index do|link, index|
        next if already_inserted_equties.include? link.split('=').last

        file_name = "summary_#{link.split("=").last.gsub!(/[^0-9A-Za-z]/, '_')}.gz"
        page      = peon.give(file:file_name, subfolder:@subfolder + "/" + "equities") rescue nil
        next if page.nil?

        data_hash = parser.parse_equities(page, data_source_url, link.gsub(' ', '%20'), countries[index], exchanges[index])
        data_array << data_hash unless data_hash.nil?
        keeper.insert_equities(data_array) unless data_array.empty?
      end
    end
  end

  private

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def directory_size(path)
    require 'find'
    size = 0
    Find.find(path) do |f|
      size += File.stat(f).size
    end
    size
  end

  def create_zip(file_name)
    obj = ZipFileGenerator.new("#{storehouse}store", "#{storehouse}trash/#{Hamster::project_number}_#{file_name}.zip")
    obj.write
  end

  def upload_zip(file_name)
    require "#{Dir.pwd}/lib/ashman/ashman"
    ashman = Hamster::Ashman.new({:aws_opts => {}, account: :hamster, bucket: 'hamster-storage1'})
    ashman.upload(key: "project_#{Hamster::project_number}_#{file_name}", file_path: "#{storehouse}trash/#{Hamster::project_number}_#{file_name}.zip")
    clean_dir("#{storehouse}trash")
  end

  def tars_to_aws
    file_name = "Run_Id_#{peon.list.min.to_i}_till_#{peon.list.max.to_i}"
    path = "#{storehouse}store"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 1000 # Mb
      create_zip(file_name)
      clean_dir(path)
      upload_zip(file_name)
    end
  end

  def get_file_name(link)
    link.split("=").last.gsub(/([%][2][0])/, "_").gsub!(/[^0-9A-Za-z]/, '_')
  end

  def get_already_downloaded_files(folder_name)
    peon.list(subfolder:@subfolder + "/" + "#{folder_name}").map{|e| e.gsub("#{folder_name}_", '').gsub('.gz', '')} rescue []
  end

  def store_info
    data_array = []
    files = peon.list(subfolder:@subfolder + "/" + "info") rescue []
    files.each do |file|
      page = peon.give(file:file, subfolder:@subfolder + "/" + "info") rescue nil
      next if page.nil?
      data_hash = parser.parse_info(page)
      data_array << data_hash unless data_hash.nil? or data_hash.empty?
      if data_array.count > 1999
        keeper.insert_info(data_array)
        data_array = []
      end
    end
    keeper.insert_info(data_array) unless data_array.empty?
    keeper.set_is_deleted_info
  end

  def download_equity_page(links, already_inserted_equties)
    links.each do |link|
      next if already_inserted_equties.include? link.split('=').last

      page = scraper.connect_to(link)
      file_name = "summary_#{link.split("=").last.gsub!(/[^0-9A-Za-z]/, '_')}"
      save_file(page, file_name, "equities")
    end
  end

  def store_prices
    data_array = []
    files = peon.list(subfolder: @subfolder +"/"+ "price") rescue []
    files.each do |file|
      page = peon.give(file:file, subfolder: @subfolder + "/" + "price") rescue nil
      next if page.nil?
      data_hash = parser.price_parsing(page)
      data_array << data_hash unless data_hash.nil? or data_hash.empty?
      if data_array.count > 1999
        keeper.insert_prices(data_array)
        data_array = []
      end
    end
    keeper.insert_prices(data_array) unless data_array.empty?
    keeper.set_is_deleted
  end

  attr_accessor :keeper, :parser, :scraper

  def save_file(response, file_name, sub_folder)
    peon.put content:response.body, file: file_name.to_s, subfolder: @subfolder + "/" + sub_folder
  end
end
