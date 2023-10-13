# frozen_string_literal: true

require_relative '../models/us_dept_agricultural_archive'
require_relative '../lib/ag_scraper'

class AGScraper < Hamster::Scraper
  
  DOMAIN = 'https://www.ars.usda.gov'
  SUB_PATH = '/news-events/news-archive/?year='
  SUB_FOLDER = 'agricultural_archive_news_' + Date.today.year.to_s

  def initialize
    super
    @already_processed_links = AgTable.pluck(:link)
    @downloaded_file_names = peon.give_list(subfolder: SUB_FOLDER).map{|e| e.split('.')[0]}
    @data_array = []
    @parser_obj = AGParser.new
  end
  
  def download
    begin
      save_html_pages
    rescue Exception => e
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload Error:\n#{e.full_message}", use: :slack)
    end
  end

  def scrape
    begin
      process_each_file
    rescue Exception => e
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape Error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_each_file
    year = SUB_FOLDER.split("_").last
    inner_files = peon.give_list(subfolder: SUB_FOLDER) - ['main_page.gz']
    main_page = peon.give(subfolder: SUB_FOLDER, file: 'main_page')
    links = @parser_obj.get_inner_links(main_page)
    links.each do |link|
      next if @already_processed_links.include? link
      file_md5 = Digest::MD5.hexdigest link
      file_name = file_md5
      next unless @downloaded_file_names.include? file_name
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      data_hash = @parser_obj.parse(file_content, main_page, link, year)
      @data_array.append(data_hash)
      AgTable.insert_all(@data_array) unless @data_array.empty?
      @data_array = []
    end
  end
  
  def save_html_pages
    filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @year = Date.today.year.to_s
    data_source_url = DOMAIN + SUB_PATH + @year
    main_page = connect_to(data_source_url, proxy_filter: filter)&.body
    links = @parser_obj.get_inner_links(main_page)
    save_file(main_page, data_source_url , true)
    process_inner_pages(links, filter) 
  end

  def save_file(html, file_name , main_page_flag = false)
    file_name = "main_page" if main_page_flag
    peon.put content: html, file: "#{file_name}", subfolder: SUB_FOLDER
  end
  
  def process_inner_pages(links, filter)
    links.each do |l|
      next if @already_processed_links.include? l
      file_name = Digest::MD5.hexdigest l
      next if @downloaded_file_names.include? file_name
      page = connect_to(l, proxy_filter: filter)&.body
      save_file(page, file_name)
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end
end
