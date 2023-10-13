require_relative '../models/us_dept_cftc_categories'
require_relative '../models/us_dept_cftc_categories_article_links'
require_relative '../lib/us_dept_cftc_scrape'

class UsDeptCftcCategoriesScrape <  Hamster::Scraper

  MAIN_URL = "https://www.cftc.gov/PressRoom/PressReleases"
  ROOT_URL = "https://www.cftc.gov"
  SOURCE_START = "https://www.cftc.gov/PressRoom/PressReleases?combine=&field_press_release_types_value="
  SOURCE_END = "&field_release_number_value=&prtid=All&year=all&page="

  def initialize
    super
    @processed_categories = UsDeptCftcCategories.pluck(:category)
    @saved_links = UsDeptCftcCategoriesArticleLinks.pluck(:article_link)
  end

  def main
    categories_parser
    article_links_scraper
  end

  def connect_to(url)
    retries = 0

    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def categories_parser
    hash_array = []
    document = connect_to(MAIN_URL)
    all_categories = document.css("select#edit-field-press-release-types-value option")[1..-1].map{|e| e.text}
    all_categories.each do |category|
      next if @processed_categories.include? category
      data_hash = {
        category: category,
        data_source_url: MAIN_URL
      }
      hash_array.push(data_hash)
    end
    UsDeptCftcCategories.insert_all(hash_array) if !hash_array.empty?
  end

  def article_links_scraper
    @processed_categories.each do |category|
      category_id = UsDeptCftcCategories.where(:category => category).pluck(:id)[0]
      page_number = 0
      flag = false
      
      while true
        data_source_url = "#{SOURCE_START}#{category}#{SOURCE_END}#{page_number}"
        @document = connect_to(data_source_url)
        flag = links_parser(category_id, data_source_url , flag)
        break if flag == true
        page_number +=1
      end 
    end
  end

  def links_parser(category_id ,data_source_url ,flag)
    hash_array = []
    all_links = @document.css("div.view-content table tbody tr").map{|e| e.css("td[2] a")[0]['href'] rescue "-"}

    all_links.each do |link|
      article_link = "#{ROOT_URL}#{link}"
      next if @saved_links.include? article_link
      data_hash = {
        article_link: "#{ROOT_URL}#{link}",
        prlog_category_id: category_id,
        data_source_url: data_source_url
      }
      hash_array.push(data_hash)
    end
    UsDeptCftcCategoriesArticleLinks.insert_all(hash_array) if !hash_array.empty?
    flag = true if hash_array.count < all_links.count
    flag
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end
end
