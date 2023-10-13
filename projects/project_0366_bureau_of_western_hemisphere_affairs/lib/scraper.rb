# frozen_string_literal: true
require_relative '../models/table'
require_relative '../models/table_tags'
require_relative '../models/table_tags_article_links'
require_relative '../lib/parser'

class ScraperClass < Hamster::Scraper
  
  DOMAIN = 'https://www.state.gov'
  SUB_PATH = '/bureau-of-western-hemisphere-affairs-releases/?results=100'
  SUB_FOLDER = 'western_hemisphere_affairs'

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
    save_html_pages
    process_each_file
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
      data_hash, tags = @parser_obj.parse(file_content, title, link, date, type)
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
      TableTAlinks.insert(tag_id: id[0], article_link: link)
    end
  end
  
  def save_html_pages
    data_source_url = DOMAIN + SUB_PATH
    outer_page, code = connect_to(data_source_url)
    save_file(outer_page, "outer_page")
    links = @parser_obj.get_inner_links(outer_page.body)
    process_inner_pages(links) 
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end
  
  def process_inner_pages(links)
    links.each do |l|
      file_name = Digest::MD5.hexdigest l
      next if @downloaded_file_names.include? file_name
      page, code = connect_to(l)
      next if page.nil?
      save_file(page, file_name)
    end
  end

  def headers
    {
      "Authority" => "www.state.gov",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
      }
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , headers: headers, proxy_filter: @proxy_filter)
      if [301, 302].include? response&.status
        url = response.headers["location"]
        response = connect_to(url)
        return
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end
end
