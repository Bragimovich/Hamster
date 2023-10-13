# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/keyword'
require 'pry'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper  = nil
    @project_number = "0007"
  end

  def resume_running(from_keyword = 'aaaa', to_keyword='zzzz')
    logger.debug "Keyword: "
    logger.debug keeper.current_keyword
    keyword = keeper.current_keyword
    if keyword.nil?
      keyword = from_keyword
    end
    loop do
      logger.debug "Search : #{keyword}"
      process_search(keyword)      
      break if keyword == to_keyword
      keyword = Keyword.next(keyword)
    end
    keeper.finish
  end

  def process_search(keyword)
    logger.debug "Resume Running"
    @scraper = nil unless scraper.nil?
    @scraper = Scraper.new
    begin
      scraper.landing
    rescue Exception => e
      logger.debug e.full_message
      Hamster.report(to: 'Frank Rao', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n error on landing with search keyword #{keyword} \n #{e.full_message}", use: :slack)
      return if e.full_message.include?("no_response_on_landing")
    end
    retries = 4
    begin
      scraper.search_bussearchnprofile(keyword)
    
      doc = scraper.get_doc
      links = parser.get_links(doc)
      logger.debug links
      while scraper.is_next_page
        logger.debug "Next Page"
        scraper.go_next_page
        doc = scraper.get_doc
        links += parser.get_links(doc)
      end
    rescue Exception => e
      if scraper.get_current_url && scraper.get_current_url.include?("/?ctr=")
        links = [scraper.get_current_url]
      else        
        # retries -= 1
        # unless retries == 0
        #   logger.debug "Retrying search_bussearchnprofile"
        #   @scraper = nil unless scraper.nil?
        #   @scraper = Scraper.new
        #   scraper.landing
        #   retry
        # end
        links = []
      end
    end
    
    keeper.start_processing_keyword(keyword)
    store_data(links)
    # scraper.clear_bussearchnprofile
    scraper.close_browser
    @scraper = nil
  end

  def store_data(links)
    links.each do |link|
      next if link.nil? || link.empty?
      logger.debug "processing: #{link}"
      unless keeper.is_not_stored_license(link)
        logger.debug 'Skipped. already stored.'
        next
      end
      doc = scraper.get_detail(link) rescue nil
      next if doc.nil?
      begin
        detail_obj = parser.parse_detail(doc)
        detail_obj[:general] = detail_obj[:general].merge({"license_url" => link})
        keeper.update_data(detail_obj)
      rescue Exception => e
        logger.debug e.full_message
        # Hamster.report(to: 'Frank Rao', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n error on storing link #{link} \n #{e.full_message}", use: :slack)
      end 
    end
  end
  
  private
    attr_accessor :keeper, :parser, :keyword_generator, :scraper

end
