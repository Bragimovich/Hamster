# frozen_string_literal: true

require_relative '../models/us_dept_dos_boeea'
require_relative '../models/us_dept_dos_boeea_tags'
require_relative '../models/us_dept_dos_boeea_tags_article_links'
require_relative '../lib/parser'

class ScraperClass < Hamster::Scraper
  
  DOMAIN = 'https://www.state.gov'
  SUB_PATH = '/bureau-of-european-and-eurasian-affairs-releases/?results=100'
  SUB_FOLDER = 'european_eurasian_affairs'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_inserted_links = Table.pluck(:link)
    @inserted_tags = TableTags.pluck(:tag)
    @downloaded_file_names = peon.give_list(subfolder: SUB_FOLDER).map{|e| e.split('.')[0]}
    @data_array = []
    @parser_obj = ParserClass.new
  end
  
  def download
    begin
      save_html_pages
    rescue Exception => e
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  def scrape
    begin
      process_each_file
    rescue Exception => e
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_each_file
    outer_page = peon.give(subfolder: SUB_FOLDER, file: 'outer_page.gz')
    downloaded_files = peon.give_list(subfolder: SUB_FOLDER)
    records = @parser_obj.get_outer_records(outer_page)
    records.each do |record|
      title, link, date, type = @parser_obj.process_outer_record(record)
      next if @already_inserted_links.include? link
      file_md5 = Digest::MD5.hexdigest link
      file_name = file_md5 + '.gz'
      next unless downloaded_files.include? file_name
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      data_hash, tags= @parser_obj.parse(file_content, title, link, date, type)
      next if data_hash.nil?
      @data_array.append(data_hash)
      tags_table_insertion(tags, link) unless tags.empty?
      if @data_array.count > 10
        Table.insert_all(@data_array)
        @data_array = []
      end
    end
    Table.insert_all(@data_array) unless @data_array.empty?
  end

  def tags_table_insertion(tags,link)
    tags.each do |tag|
      unless @inserted_tags.include? tag
        TableTags.insert(tag: tag)
        @inserted_tags.push(tag)
      end
      id = TableTags.where(:tag => tag).pluck(:id)
      TableTAlinks.insert(tag_id: id[0] , article_link: link)
    end
  end
  
  def save_html_pages
    data_source_url = DOMAIN + SUB_PATH
    outer_page, code = connect_to(url: data_source_url, headers: headers, proxy_filter: @proxy_filter)
    save_file(outer_page, "outer_page")
    links = @parser_obj.get_inner_links(outer_page.body)
    process_inner_pages(links) 
  end

  def headers
    {
    "Authority" => "www.state.gov",
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language" => "en-US,en;q=0.9",
    "Sec-Ch-Ua" => "\"Google Chrome\";v=\"111\", \"Not(A:Brand\";v=\"8\", \"Chromium\";v=\"111\"",
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Ch-Ua-Platform" => "\"Linux\"",
    "Sec-Fetch-Dest" => "document",
    "Sec-Fetch-Mode" => "navigate",
    "Sec-Fetch-Site" => "none",
    "Sec-Fetch-User" => "?1",
    "Upgrade-Insecure-Requests" => "1",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
    }
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end
  
  def process_inner_pages(links)
    links.each do |l|
      file_name = Digest::MD5.hexdigest l
      next if @downloaded_file_names.include? file_name
      page, code = connect_to(url: l, headers: headers, proxy_filter: @proxy_filter)
      next if page.nil?
      save_file(page, file_name)
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    25.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302].include?(response.status)
    end
    response
  end

end
