# frozen_string_literal: true
require_relative '../lib/parser_class'
require_relative '../lib/keeper'
require_relative '../lib/scraper_class'
class Manager < Hamster::Scraper
  SUB_FOLDER = 'US_Department_of_Agriculture'

  def initialize
    super
    @downloaded_file_names = peon.give_list(subfolder: SUB_FOLDER)
    
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @downloaded_filename_link_dict = {}
    @outer_downloaded_pages = {}
    
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      outer_pages = table.select{|x| x[0].include?("outer_page_")}
      outer_pages.map{|x| @outer_downloaded_pages[x[0]]= x[1]}
      table.map{ |x| @downloaded_filename_link_dict[x[0]] = x[1] }
    end
  end

  def download
    begin
      @scraper = ScraperClass.new
      @scraper.download
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  def store
    begin
      @parser_obj = ParserClass.new
      @keeper = DBKeeper.new
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private
  
  def process_each_file
    @outer_downloaded_pages.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name[0])
      puts "Parsing outer_page #{file_name[1]}".yellow
      links_in_outer_page = @parser_obj.get_inner_divs(file_content)
      links_in_outer_page.each do |each_div|
        par_hash = @parser_obj.data_from_div(each_div)
        puts "Processing Inner link #{par_hash[:link]}".blue
        file_md5 = Digest::MD5.hexdigest(par_hash[:link])
        file_name = file_md5 + '.gz'
        file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        par_hash2 = @parser_obj.parse_each_article(file_content)
        result = par_hash.merge(par_hash2)
        @keeper.store(result)
      end
    end
  end
end 
