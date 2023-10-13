# frozen_string_literal: true

require_relative '../models/us_dept_fcc_categories'
require_relative '../models/us_dept_fcc_categories_article_links'
require_relative '../models/us_dept_fcc'

class UsDeptFccScrape <  Hamster::Scraper

  ROOT_URL = "https://www.fcc.gov"

  def initialize
    super
    @filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @all_categories = UsDeptFccCategories.select(:id, :category)
    @all_links = UsDeptFcc.pluck(:link)
    @all_downloaded_files = Dir["#{storehouse}store/#{Date.today.year}/*.txt"].map{|f| f.split('/').last} rescue []
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end

  def scraper
    year = Date.today.year
    flag = true
    @data_array = []
    page_number = 0
    while flag == true
      data_source_url = "https://www.fcc.gov/news-events/headlines?year_released=2023&items_per_page=100"
      @parsed_page = connect_to(data_source_url)
      @parsed_page = Nokogiri::HTML(@parsed_page.body)
      break if @parsed_page.css(".pane-content").text.include? "No results found."
      parser(data_source_url , year)
      page_number+=1
      flag = false
    end
  end

  def download_file(file_link , year, retries = 50)
    begin
      proxy = PaidProxy.all.to_a.shuffle.first
      proxy_string = "#{proxy["login"]}:#{proxy["pwd"]}@#{proxy["ip"]}:#{proxy["port"]}"
      FileUtils.mkdir_p("#{storehouse}store/#{year}")
      system("http_proxy=http://#{proxy_string} wget -P #{storehouse}store/#{year} #{file_link}")
    rescue Exception => e
      raise if retries <= 1
      download_file(file_link , year, retries - 1)
    end
  end

  def parser(data_source_url , year)
    article_links = get_article_links
    dataset = UsDeptFccCategoriesArticleLinks
    check_array = []
    article_links.each do |link|
      next if @all_links.include? link
      inner_page = connect_to(link)
      file_name  = Digest::MD5.hexdigest link
      save_page(inner_page, file_name, "#{Date.today.year}/html")
      inner_page =  Nokogiri::HTML(inner_page.body)
      file_link = inner_page.css('a.document-link').map { |e| e['href'] }
      file_link = file_link.select { |e| e.include? '.txt'}[0] rescue nil
      file_name = file_link.split('/').last unless file_name.nil?
      next if @all_downloaded_files.include? file_name
      download_file(file_link , year) unless file_link.nil?
    end
  end

  def get_article_links
    @parsed_page.css("article").map{|e| "#{ROOT_URL}" +e.css('div.headline-title a')[0]['href'] rescue nil}.reject {|key| key.nil?}
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def fetch_date(data)
    date = data.css("li").select{|e| e.text.include? "Released On:"}[0]
    date = Date.parse(date.text.split(":").last) rescue nil
    date 
  end
end
