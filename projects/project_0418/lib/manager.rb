# frozen_string_literal: true
require_relative '../lib/parser_class'
require_relative '../lib/keeper'
require_relative './scrapper_class'
require 'csv'

class Manager < Hamster::Scraper
  BASE_URL = "https://www.fbi.gov/news/press-releases"
  SUB_FOLDER = 'FederalBureauofInvestigationUsDeptOfJustice'
  
  def initialize
    super
    @scraper = ScraperClass.new
    @parser_obj = ParserClass.new
    @keeper = DBKeeper.new
    
    # initailizing differnet data structures that are commonly used in both download and store method
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @filename_to_link = {}
    @outerfilename_to_link = {}
    @link_to_redirectlink = {}
    
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @filename_to_link[x[0]] = x[1] }
      outer_pages = table.select{|x| x[0].include?("outer_page_")}
      outer_pages.map{|x| @outerfilename_to_link[x[0]]= x[1]}
      table.map{ |x| @link_to_redirectlink[x[1]] = x[2] }
    end
  end

  # passing this link as an argument to override base_url and start scrapping from that link
  def download(link = nil)
    link = BASE_URL unless link.present?
    
    begin
      while true
        break if link == nil or link == ""

        file_name = "outer_page_" + Digest::MD5.hexdigest(link) + '.gz'

        if @filename_to_link[file_name].present?
          outer_page_prime = peon.give(subfolder: SUB_FOLDER, file: file_name)
          next_link = @parser_obj.get_next_link(outer_page_prime)
        else
          # download outer page
          next_link ,page_response = download_and_save_outer_page(link)
          
          # download all inner pages of above outer page
          if page_response.present?
            download_and_save_inner_divs_of_page(page_response)
          end
        end

        # Added extra next_link variable for code readability 
        link = next_link
      end
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  # Note: Why below function was needed
  # This function is combination of download and store
  # As this website contains a lot of data (80k) and we have to scrape this website 4 times daily to
  # get the recent data. So that's why i have created this function it will download and store first two pages
  # each time when scrapper will run. In this way database will be in sync with the website
  def download_and_store
    link = BASE_URL
    (1..2).each do |i|
      next_link , page_response = download_and_save_outer_page(link)
      if page_response.present?
        download_and_save_inner_divs_of_page(page_response ,daily_sync = true)
      end
      link = next_link
    end
  end

  private

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name,link, redirected_link)
    @link_to_redirectlink[link] = redirected_link
    rows = [[file_name , link ,redirected_link]]
    File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
  end

  def download_and_save_outer_page(link)
    # This function will download and save web page and will return the next link of page to be saved and its response body
    outer_page, status , outer_url_prime = @scraper.download_web_page(link)

    return [nil,nil] if status != 200
    return [nil,nil] if @parser_obj.get_inner_divs(outer_page.body).count == 0
    
    file_name = "outer_page_" + Digest::MD5.hexdigest(link) + '.gz'
    # save outer page file
    save_file(outer_page ,file_name)
    save_csv(file_name , link , outer_url_prime)
    [@parser_obj.get_next_link(outer_page.body) , outer_page]
  end

  def download_and_save_inner_divs_of_page(outer_page,daily_sync = false)
    # daily_sync argument: Based on that argument we will decide weather we will save results in db as well or not
    @parser_obj.get_inner_divs(outer_page.body).each do |inner_div|
      inner_link = @parser_obj.get_article_link_from_inner_div(inner_div)
      inner_file_name = Digest::MD5.hexdigest(inner_link) + 'gz'
      # move to next link if file already there
      next if @filename_to_link[inner_file_name].present?
      inner_page, status , inner_url_prime = @scraper.download_web_page(inner_link)
      next if status != 200
      save_file(inner_page, inner_file_name)
      save_csv(inner_file_name, inner_link, inner_url_prime)
      # save inner divs in database too if daily_sync argument is true
      if daily_sync
        save_inner_div(inner_div, inner_page.body)
      end
    end
  end

  def process_each_file
    @outerfilename_to_link.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name[0])
      puts "Parsing outer_page #{file_name[1]}".yellow
      @parser_obj.get_inner_divs(file_content).each do |inner_div|
        par_hash = @parser_obj.parse_inner_div(inner_div)
        puts "Processing Inner link #{par_hash[:link]}".blue
        file_name = Digest::MD5.hexdigest(par_hash[:link]) + '.gz'
        file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        save_inner_div(inner_div , file_content)
      end
    end
  end


  def save_inner_div(inner_div,file_content)
    par_hash = @parser_obj.parse_inner_div(inner_div)

    # redirected link of url
    redirected_link = @link_to_redirectlink[par_hash[:link]]

    par_hash2 = @parser_obj.parse_inner_article(file_content,redirected_link)

    topic_exist , t_ft = @parser_obj.footer_topic_div(file_content) 
    component_exist, c_ft = @parser_obj.footer_component_div(file_content)
    
    if topic_exist
      all_tags = @parser_obj.topic_parse(t_ft,par_hash[:link])
      @keeper.store_tags(all_tags)
      @keeper.store_tag_article(all_tags , par_hash[:link])
    end
    
    if component_exist
      list_of_components = @parser_obj.component_parse(c_ft,par_hash[:link])
      @keeper.store_bureo_article(list_of_components)
    end

    result = par_hash.merge(par_hash2)
    result[:link] = redirected_link
    @keeper.store(result)
  end

end
