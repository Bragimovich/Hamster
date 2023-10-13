require_relative '../models/us_aid'

class UsAidScrape <  Hamster::Scraper

  MAIN_URL = "https://www.usaid.gov"
  SOURCE = "https://www.usaid.gov/news-information/press-releases?page="
  SOURCE_ARCHIVE = ".usaid.gov/news-information/press-releases?page="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsAid.pluck(:link)
  end

  def request_method(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def press_release_scraper
    page_number = 0
    flag = false

    while true
      puts "Processing Page No #{page_number}".yellow
      data_source_url = "#{SOURCE}#{page_number}"
      @document = request_method(data_source_url)
      flag = press_release_parser(data_source_url, flag)
      break if flag == true
      page_number +=1
    end
  end

  def press_release_parser(data_source_url, flag)
    all_records = @document.css(".views-view-grid__item-inner")
    press_release_data = []
    all_records.each do |record|
      article_link = record.css("a")[0]['href'] rescue nil
      next if article_link.nil?
      article_link = MAIN_URL + article_link
      next if @already_fetched_articles.include? article_link
      article , contact_info = fetch_article(article_link)
      next if article.nil? and contact_info.nil?
      data_hash = {}
      data_hash = {
        title: record.css("h3 span").text.squish,
        teaser: record.css(".field--name-body").text.squish,
        article: article,
        link: article_link,
        date: Date.parse(record.css("time").text.strip),
        contact_info: contact_info,
        data_source_url: data_source_url
      }
      press_release_data.push(data_hash)
    end
    UsAid.insert_all(press_release_data) if !press_release_data.empty?
    flag = true if press_release_data.count < 10
    flag
  end

  def news_archive_scraper
    years = ['https://2012-2017', 'https://2017-2020']
    years.each do |year|
      page_number = 0
      while true
        puts "Processing Page No #{page_number}".yellow
        data_source_url = "#{year}#{SOURCE_ARCHIVE}#{page_number}"
        response = Hamster.connect_to(url: data_source_url,proxy_filter: @proxy_filter)
        reporting_request(response)
        @document = Nokogiri::HTML(response.body)

        if @document.css("p").text.include? "Sorry, no press articles match your selection."
          puts "No More Data Available".red
          break
        end
        press_release_parser(data_source_url)
        page_number +=1
      end
    end
  end

  def fetch_article(link)
    contact_info = []
    article_data = request_method(link)

    (article_data.css("html").attribute("lang").text != "en") ?  article = nil : article = "Data is available"

    (article_data.text.include? "Page not found") ? article = nil  :  article_data
    return [nil , nil] if article.nil?

    contact_info << article_data.css(".usa-footer__contact-info strong").text rescue nil
    contact_info2 = article_data.css(".field--name-body .font-body-md").text
    contact2 = (contact_info2.size) > 255 ? "" : contact_info2
    contact_info <<  contact2 rescue nil
    contact_info.reject{|e| e.empty? }.empty? ? (contact_info = nil) : (contact_info = contact_info.join(", "))

    article_form = article_data.css(".field--type-text-with-summary")[3...-1]
    article = (article_form == []) ? article_data.css(".field--type-text-with-summary")[1] : article_form

    article.css("img").remove
    article.css("script").remove
    article.css("figure").remove
    article.css("div.token-img-right").remove

    if !article.css("div").map{|e| e.attribute("lang")}.reject(&:nil?).empty?
      if article.css("div").map{|e| e.attribute("lang")}.reject(&:nil?).first.text != "en"
        article.css("div").select{|e| e.attribute("lang")}.first.remove 
      end
    end
    [article.to_s, contact_info]
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
