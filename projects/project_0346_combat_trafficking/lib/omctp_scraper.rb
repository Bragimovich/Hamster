require_relative '../models/us_dept_dos_omctp'
require_relative '../models/us_dept_dos_omctp_tags'
require_relative '../models/us_dept_dos_omctp_tags_article_links'
require_relative '../lib/omctp_parser'

class OmctpScraper < Hamster::Scraper
  DOMAIN = 'https://www.state.gov'
  SUB_PATH = '/remarks-and-releases-office-to-monitor-and-combat-trafficking-in-persons-2/'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed_links = OmctpTable.pluck(:link)
    @inserted_tags = OmctpTags.pluck(:tag)
    @downloaded_file_names = peon.give_list(subfolder: @subfolder).map{|e| e.split('.')[0]}
    @data_array = []
    @parser_obj = OmctpParser.new
    @subfolder = 'office_to_monitor_and_combat_trafficking_in_persons'
  end

  def download
    begin
      save_html_pages
    rescue Exception => e
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
  end

  def scrape
    begin
      process_each_file
    rescue Exception => e
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_each_file
    outer_page = peon.give(subfolder: @subfolder, file: 'outer_page.gz')
    downloaded_files = peon.give_list(subfolder: @subfolder)
    records = @parser_obj.get_outer_records(outer_page)
    records.each do |record|
      title, date, link = @parser_obj.process_outer_record(record)
      next if @already_processed_links.include? link
      file_md5 = Digest::MD5.hexdigest link
      file_name = file_md5 + '.gz'
      next unless downloaded_files.include? file_name
      file_content = peon.give(subfolder: @subfolder, file: file_name)
      data_hash, tags= @parser_obj.parse(file_content, title, date, link)
      next if data_hash.nil?
      @data_array.append(data_hash)
      tags_table_insertion(tags, link) unless tags.empty?
      if @data_array.count > 9
        OmctpTable.insert_all(@data_array)
        @data_array = []
      end
    end
    OmctpTable.insert_all(@data_array) unless @data_array.empty?
  end

	def tags_table_insertion(tags,link)
    tags.each do |tag|
      unless @inserted_tags.include? tag
        OmctpTags.insert(tag: tag)
        @inserted_tags.push(tag)
      end
      id = OmctpTags.where(:tag => tag).pluck(:id)
      OmctpTALinks.insert(tag_id: id[0] , article_link: link)
    end    
  end

  def save_html_pages
    data_source_url = DOMAIN + SUB_PATH
    outer_page = connect_to(url: data_source_url,  headers: headers)
    all_data_source_url = "#{data_source_url}?results=#{@parser_obj.get_total_length(outer_page.body)}"
    save_file(outer_page, "outer_page")
    links = @parser_obj.get_inner_links(outer_page.body)
    process_inner_pages(links)
  end

  def headers
    {
      "Authority" => "www.state.gov",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"107\", \"Chromium\";v=\"107\", \"Not=A?Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    }
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: @subfolder
  end

  def process_inner_pages(links)
    links.each do |link|
      file_name = create_md5_hash(link)
      next if @downloaded_file_names.include? file_name
      page = connect_to(url: link, headers: headers)
      next if @parser_obj.get_check_value(page.body) == ""
      save_file(page, file_name) 
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash
  end
end
