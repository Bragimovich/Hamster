require_relative '../models/us_dept_housing_and_urban_development'
require_relative '../lib/scraper.rb'

class ScraperArchive <  Hamster::Scraper

  MAIN_URL = "https://archives.hud.gov/news/index.cfm"
  BASE_URL = "https://archives.hud.gov"
  
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsDept.pluck(:link)
    @press_release_data = []
    @scraper_object = Scraper.new
  end
  
  def main
    all_release_links = get_all_release_links

    all_release_links.each do |link|
      next if @already_fetched_articles.include? link
      document = @scraper_object.connect_to(link)
      parser(document,link)
      if @press_release_data.count == 50
        UsDept.insert_all(@press_release_data) if !@press_release_data.empty?
        @press_release_data = []
      end
    end

    UsDept.insert_all(@press_release_data) if !@press_release_data.empty?
    @press_release_data = []
  end 

  def get_all_release_links
    all_release_links = []
    all_year_links = []
    document = @scraper_object.connect_to(MAIN_URL)
    document.css("ul li a").map{|e| all_year_links << "#{BASE_URL}/news/"+ e["href"]}
    all_year_links = all_year_links.reject{|e| }

    all_year_links.each do |year_link|
      next if year_link.split("/")[-1].split(".")[0].to_i < 2000
      document = @scraper_object.connect_to(year_link)
      document.css("div#main ul li a").map{|e| all_release_links << BASE_URL + e["href"]}
    end
    all_release_links
  end

  def parser(document, link)
    release_no = "HUD No. " + link.split("/pr")[-1].split(".")[0].strip
    year = release_no.split("HUD No. ")[-1].split("-")[0].to_i
    title = document.css("div#main h3").text.split("\n")[0].strip rescue nil
    date,contact_info = fetch_date_contact(document)
    article = fetch_article(document)

    teaser = @scraper_object.fetch_teaser(article)
    data_source_url = ""
    if year < 10
      year = "0" + year.to_s
    end
    data_source_url = "https://archives.hud.gov/news/20#{year}.cfm"

    data_hash = {
      title: title,
      teaser: teaser,
      release_no: release_no,
      contact_info: contact_info,
      article: article.to_s,
      link: link,
      date: date,
      data_source_url: data_source_url,
    }
    @press_release_data.push(data_hash)
  end

  def fetch_date_contact(flag, document)
    all_rows = document.css("div#main table td").text.split("\n").map{|e| e.strip rescue ""}.reject{|e| e == ""}
    date = nil
    contact_info = nil

    all_rows.each do |e|
      date_check = Date.parse(e).to_date rescue "-"
      if date_check != "-"
        date = date_check
        break    
      end
    end

    all_tds = document.css("div#main table td")

    all_tds.each do |td|
      if td.text.include? "(202)" or (td.text.include? ")" and td.text.include? "(")
        contact_info = td.to_s
        break
      end
    end
    [date, contact_info]
  end

  def fetch_article(flag, document)
    article = document.css("div#main")

    if article.nil? or article.empty? or article == ""
      article = document.css("table[bgcolor='CCCCCC']").first.css("tr")[2]
    end

    if article.nil?  or article == ""
      article = document.css("table[bgcolor='CCCCCC']").first.css("tr")[1]
    end

    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article
  end 
end
