# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper

  BASE_URL = "https://www.opensocietyfoundations.org/grants/past?page="
  SUB_FOLDER = 'open_society_foundations'

  attr_reader :parser_obj , :keeper , :scraper

  def download
    @downloaded_file_names = peon.give_list(subfolder: SUB_FOLDER)
    scraper = Scraper.new
    # Note: Need this parser here to check the breaking condition
    parser_obj = ParserClass.new
    initial_page = 1
    
    begin
      while true
        link = BASE_URL+initial_page.to_s
        puts "#{link}".yellow
        # filename in md5 hash
        file_name = Digest::MD5.hexdigest(link) + '.gz'
        # increasing page count
        initial_page += 1        
        # continue if file is already downloaded
        next if @downloaded_file_names.include?(file_name)
        outer_page, status = scraper.download_web_page(link)
        next if status != 200
        # breaking condition
        break if parser_obj.get_inner_divs(outer_page.body).count == 0
        # saving response on disk
        save_file(outer_page, file_name)
      end
    rescue Exception => e
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def process_each_file
    parser_obj = ParserClass.new
    keeper = DBKeeper.new
    @downloaded_file_names = peon.give_list(subfolder: SUB_FOLDER)
    @downloaded_file_names.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      inner_divs = parser_obj.get_inner_divs(file_content)
      inner_divs.each do |inner_div|
        result = parser_obj.parse_each_div(inner_div)
        if result.present? && result.class.to_s == "Hash"
          keeper.store(result)
        end
      end
    end
  end
end
  