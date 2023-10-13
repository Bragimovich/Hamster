# frozen_string_literal: true

require_relative '../models/us_dept_dos_boiesa'
require_relative '../models/us_dept_dos_boiesa_tags'
require_relative '../models/us_dept_dos_boiesa_tags_article_links'
require_relative '../lib/boiesa_parser'


class BoiesaScraper < Hamster::Scraper
  
  DOMAIN = 'https://www.state.gov'
  SUB_PATH = '/remarks-and-releases-bureau-of-oceans-and-international-environmental-and-scientific-affairs/?results=30'
  SUB_FOLDER = 'oceans_and_scientific_affairs'

  def initialize
    super
    @agent = Mechanize.new
    @agent.user_agent_alias = "Windows Mozilla"
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed_links = BoiesaTable.pluck(:link)
    @inserted_tags = BoiesaTags.pluck(:tag)
    @already_saved_links = peon.give_list(subfolder: SUB_FOLDER).map{|e| 'https://' + e.gsub('.gz', '').gsub("__",".").gsub("_","/")} 
    @data_array = []
    @parser_obj = BoiesaParser.new
  end
  
  def download
    begin
      save_html_pages
    rescue Exception => e
      Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  def scrape
    begin
      process_each_file
    rescue Exception => e
      Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_each_file

    inner_files = peon.give_list(subfolder: SUB_FOLDER)
    loop do
      break if inner_files.empty?
      file = inner_files.pop
      link = 'https://' + file.gsub('.gz', '').gsub("__",".").gsub("_","/")
      next if @already_processed_links.include? link
      file_content = peon.give(subfolder: SUB_FOLDER, file: file)
      data_hash, tags = @parser_obj.parse(file_content, link)
      next if data_hash == {}
      @data_array.append(data_hash)
      tags_table_insertion(tags,link) unless tags.empty?
      BoiesaTable.insert_all(@data_array) unless @data_array.empty?
      @data_array = []
    end
    
  end

  def tags_table_insertion(tags,link)
    tags.each do |tag|
      unless @inserted_tags.include? tag
        BoiesaTags.insert(tag: tag)
        @inserted_tags.push(tag)
      end
      id = BoiesaTags.where(:tag => tag).pluck(:id)
      BoiesaTALinks.insert(tag_id: id[0], article_link: link)
    end
  end
  
  def save_html_pages
    data_source_url = DOMAIN + SUB_PATH
    main_page, code = connect_to(data_source_url)
    links = @parser_obj.get_inner_links(main_page.body)
    process_inner_pages(links.reverse) 
  end

  def save_file(html, l)
    name = l.split("//").last.gsub("/","_").gsub(".","__")
    peon.put content: html.body, file: "#{name}", subfolder: SUB_FOLDER
  end
  
  def process_inner_pages(links)
    links.each do |l|
      next if @already_saved_links.include? l
      p l
      page, code = connect_to(l)
      page = mechanize_connect(l) unless code == 200
      save_file(page, l)
    end
  end

  def mechanize_connect(url)
    response = @agent.get(url)
  end

  def connect_to(url)
    retries = 0
    headers = {
      "Authority" => "www.state.gov",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
      "Sec-Fetch-Dest" => "document"
    }
    begin
      response = Hamster.connect_to(url: url,headers: headers, proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or response&.status == 301 or response&.status == 302 or retries == 10
    return [response, response&.status]
  end
end
