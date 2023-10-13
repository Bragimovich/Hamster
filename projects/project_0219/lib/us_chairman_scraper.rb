# frozen_string_literal: true

require_relative '../models/us_dept_chairmans_news'

class UsChairmanScraper <  Hamster::Scraper

  MAIN_URL = "https://www.finance.senate.gov/chairmans-news?maxRows=60&type=press_release"
  
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsChairmansNews.pluck(:link)
    @data_array = []
  end
  
  def connect_to(url)
    retries = 0

    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def main
    document = connect_to(MAIN_URL)
    inner_links = document.css("#browser_table a").map{|e| e["href"].squish}
    inner_links.each do |link|
     next if @already_fetched_articles.include? link
     next if link.include? "https://www.finance.senate.gov/download" 
     document = connect_to(link)
      inner_page_parser(document,link)
      if @data_array.count > 50
        UsChairmansNews.insert_all(@data_array) if !@data_array.empty?
        @data_array = []
      end
    end
    UsChairmansNews.insert_all(@data_array) if !@data_array.empty?
  end

  def inner_page_parser(document,link)
    lang_tag = document.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and lang_tag != "en"
    title = document.css(".main_page_title").first.text.strip rescue binding.pry
    subtitle = document.css(".subtitle").first.text.strip rescue nil
    contact_info = document.css(".presscontact").first.next_element.to_s rescue nil
    date = Date.parse(document.css(".date.black").first.text).to_date
    article = fetch_article(document)
    dirty_news = 1 if article.text.squish.length < 10
    teaser = fetch_teaser(article.css("#pressrelease"))
    with_table = article.css("table").empty? ? 0 : 1
    data_hash = {
      title: title,
      subtitle: subtitle,
      teaser: teaser,
      contact_info: contact_info,
      article: article.to_s,
      link: link,
      date: date,
      with_table: with_table,
      dirty_news: dirty_news,
    }
    @data_array.push(data_hash)
  end

  def fetch_article(document)
    article = document.css("#newscontent").first
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("script").remove
    article
  end
 
  def fetch_teaser(article)
    teaser = nil
    article.css("h2").remove
    article.css("h3").remove
    article.css("h1").remove
    article.css(".contactinfo").remove    
    article.children.each do |node|
      next if node.text.squish == ""
      next if node.text.squish[-5..-1].nil?
      if (node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
        teaser = node.text.squish
        break
      end
    end
    
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser == ""
        next if teaser[-2..-1].nil?
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
          break
        end
      end
    end

    teaser.length rescue return teaser

    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end

    if teaser[-1].include? ":"
      teaser[-1] = "..."
    end
    teaser = cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-', 2).last.strip
      end
    elsif teaser[0..30].upcase.include? 'WASHINGTON' and  teaser[0..10].include? '('
      teaser = teaser.split(')', 2).last.strip
    end
    teaser
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
