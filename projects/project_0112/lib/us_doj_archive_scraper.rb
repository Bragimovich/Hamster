require_relative '../models/us_doj'
require_relative '../lib/us_doj_scraper'

class UsDojArchiveScraper <  Hamster::Scraper

  MAIN_URL = "https://www.justice.gov"
  SOURCE = "https://www.justice.gov/archives/justice-news-archive"
  
  def initialize()
    super
    @scraper_object = UsDojScraper.new
  end

  def news_archive_scraper
    data = @scraper_object.request_method(SOURCE)

    all_years = data.css("div.field--name-field-page-body div.field__item table tbody tr").map{|e| e.css("th").text.gsub(":", "")}

    all_years.each_with_index do |year, ind|
      break if year == "2001"
      Date::MONTHNAMES[1..-1].each do |month|
        next if year == '2009' and month != 'January'
        puts "Processing year is #{year} and Month is #{month}".green

        year == "2009" ? (data_source_url = "https://www.justice.gov/archive/opa/pr/#{year}/#{month}/index-archive.html")  : (data_source_url = "https://www.justice.gov/archive/opa/pr/#{year}/#{month}/")  
        
        response =  Hamster.connect_to(url: data_source_url, proxy_filter: @proxy_filter )
        next if response.status !=  200
        
        @document = Nokogiri::HTML(response.body)
        all_links = get_links(year, month)
        
        news_archive_parser(data_source_url, all_links )
      end
    end
  end

  def get_links(year, month)
    all_links = @document.css("div.pressbody p").map{|e| e.css("a")[0]['href']}.empty? ? @document.css("ul li").map{|e| "/archive/opa/pr/#{year}/#{month}/#{e.css("a")[0]['href']}"} : @document.css("div.pressbody p").map{|e| e.css("a")[0]['href']}  
    all_links
  end

  def news_archive_parser(data_source_url, all_links )
    archive_data = []
    all_links.each do |link|
      article_link = "#{MAIN_URL}#{link}"
      article_data = @scraper_object.request_method(article_link)
      title = article_data.css("h1.prtitle").text.squish == "" ? article_data.css("p.title")[0].text.squish : article_data.css("h1.prtitle").text.squish

      data_hash = {}
      data_hash[:title] = title
      data_hash[:subtitle] = article_data.css("p.title")[1].text.squish rescue "-"
      data_hash[:date] = get_date(article_data)
      data_hash[:release_no] = article_data.css("p.none")[-1].text
      data_hash[:teaser] = @scraper_object.fetch_teaser(article_data)
      data_hash[:link] = article_link
      data_hash[:article] = fetch_article(article_data)
      archive_data  << data_hash
    end
    UsDoj.store(archive_data) if !archive_data.empty?
  end

  def get_date(article_data)
    data_array = article_data.css("div")[0].to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/).empty? ? article_data.css("table tr")[0].css("td")[0].to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/) : article_data.css("div")[0].to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/)
    Date.parse(data_array[1][0].squish)
  end

  def fetch_article(link)
    article = article_data.css("body")
    article.css("img").remove
    article.css("hr").remove
    article.css("h1.prtitle").remove
    article.css("p.title").remove
    article.css("script").remove
    article.to_s
  end
end
