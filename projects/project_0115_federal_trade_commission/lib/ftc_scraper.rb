require_relative '../models/ftc'

class FederalTradeCommission <  Hamster::Scraper

  SOURCE_URL = "https://www.ftc.gov"
  MAIN_URL  = "https://www.ftc.gov/news-events/news/press-releases?items_per_page=100&page="
  

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_links = Ftc.pluck(:link)
    @hash_array = []
  end

  def connect_to(url)
    retries = 0

    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def main_scraper
    page_number = 0
    @flag = false

    while true

      data_source_url = "#{MAIN_URL}#{page_number}"
      document = connect_to(data_source_url)
      main_page_parser(document , data_source_url)
      break if @flag == true
      page_number +=1
    end
  end

  def main_page_parser(document,data_source_url)
    current_page_releases = document.css("div.main div.views-row h3.node-title a")
    all_links = current_page_releases.map{|e| SOURCE_URL + e["href"]}
  
    all_links.each do |link|
      if !@already_fetched_links.map{|e| link.include? e}.reject{|e| e == false}.empty?
        next 
      end
      article_data = connect_to(link)
      release_parser(article_data,link,data_source_url)
    end
    Ftc.insert_all(@hash_array) if !@hash_array.empty?
    @flag = true if @hash_array.count < all_links.count or all_links.count == 0
    @hash_array = []
  end

  def release_parser(document,link,data_source_url)
    title = document.css("h1.node-title").text.strip
    subtitle = document.css(".field--name-field-subtitle").text.strip rescue nil
    subtitle = nil if subtitle == ""
    date = document.css(".field--name-field-date.field--type-datetime time")[0]["datetime"]
    article = fetch_article(document)
    teaser = fetch_teaser(article)
    contact_info = fetch_contact_info(document)

    data_hash = {}
    data_hash = {
    title: title,
    subtitle: subtitle,
    teaser: teaser,
    article: article.to_s,
    link: link,
    date: date,
    contact_info: contact_info,
    data_source_url: data_source_url
    }
    @hash_array << data_hash
  end

  def fetch_contact_info(document)
    contact_element = document.css(".view-header").select{|e| e.text.downcase.include? "contact information"}[0]
    if contact_element == "" or !contact_element.nil?
      contact_info = contact_element.next_element.to_s
    else
      contact_info = nil
    end
    contact_info
  end

  def fetch_teaser(article)
    teaser = nil
    article.css("p").each do |node|
      next if node.text.squish == ""
      next if node.text.squish[-3..-1].nil?
      if (node.text.squish[-3..-1].include? "." or node.text.squish[-3..-1].include? ":") and node.text.squish.length > 50
        teaser = node.text.squish
        break
      end
    end

    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 50
          break
        end
      end
    end

    if teaser.nil? or teaser == '' or teaser == '-'
      teaser = TeaserCorrector.new(article.text.squish).correct.strip
    else
      teaser = TeaserCorrector.new(teaser).correct.strip
    end
    teaser = cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? "\u0096"
      teaser = teaser.split("\u0096" , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON" or teaser[0..50].include? "TOKYO"
        teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end

  def fetch_article(document)
    document.css('img').remove
    document.css('iframe').remove
    document.css('figure').remove
    document.css('script').remove
    article = document.css("div.field--name-body.field--type-text-with-summary")[0]
    return article
  end
end
