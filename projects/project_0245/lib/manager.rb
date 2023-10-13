# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester
  MAIN_URL = 'https://www.elections.alaska.gov/doc/info/statsPPA.php'

  def initialize
    super 
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    db_processed_links = keeper.db_inserted_links
    main_page = scraper.get_response(MAIN_URL)
    save_file(main_page.body,"outer_page","#{keeper.run_id}")
    all_years = (Date.today.year-1..Date.today.year).map(&:to_s)
    all_years.each do |year|
      main_page_link = parser.fetch_main_page(main_page.body,year)
      main_page_link.each do |link , full_date|
        link = link.gsub(' ', '%20')
        next if db_processed_links.include? link
        each_month_link = scraper.get_response(link)
        file_name = Digest::MD5.hexdigest link
        (link.end_with? '.pdf') ? save_zip(each_month_link.body,file_name,"#{keeper.run_id}") : save_file(each_month_link.body, file_name, "#{keeper.run_id}")
      end
    end
  end

  def store
    db_processed_links = keeper.db_inserted_links
    inserted_records = keeper.already_inserted_md5
    main_page = peon.give(subfolder: "#{keeper.run_id}", file: "outer_page.gz")
    all_years = (Date.today.year-1..Date.today.year).map(&:to_s)
    all_years.each do |year|
      page = parser.fetch_main_page(main_page,year)
      page.each do |current_file|
        link = current_file[0].gsub(' ', '%20')
        next if db_processed_links.include? link
        file_name = Digest::MD5.hexdigest link
        if link.end_with? '.pdf'
          pdf_data = "#{storehouse}store/#{keeper.run_id}/Pdf_files/#{file_name}.pdf"
          hash_array = parser.pdf_reading(pdf_data, "#{keeper.run_id}", current_file[1], link)
        else
          htm_data = peon.give(subfolder: "#{keeper.run_id}", file: file_name)
          hash_array = parser.voters_info_parser(htm_data, keeper.run_id, current_file[1], link)
        end
        hash_array = duplication_handler(inserted_records, hash_array)
        keeper.insert_records(hash_array) unless hash_array.empty?
      end
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper, :sub_folder

  def duplication_handler(inserted_records, hash_array)
    hash_array.reject{|e| inserted_records.include? e[:md5_hash]}
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end

  def save_zip(content, file_name, sub_folder)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}/Pdf_files"
    zip_storage_path = "#{storehouse}store/#{sub_folder}/Pdf_files/#{file_name}.pdf"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end
end
