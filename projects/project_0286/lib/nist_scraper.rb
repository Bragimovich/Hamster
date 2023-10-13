# frozen_string_literal: true

require_relative '../models/us_dept_nist'
require_relative '../models/us_dept_nist_tags'
require_relative '../models/us_dept_nist_tags_article_links'


class NISTScraper <  Hamster::Scraper

  DOMAIN = "https://www.nist.gov"
  MAIN_PAGE = "https://www.nist.gov/news-events/news/search?k=&t=All&page="
  
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = NIST.pluck(:link)
    @inserted_tags = NISTTags.pluck(:tag)
    @data_array = []
  end
  
  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
    return [document,response&.status]
  end

  def main
    page_no = 0
    while true
      data_source_url = MAIN_PAGE + page_no.to_s
      document,status = connect_to(data_source_url)
      releases = document.css("div[class*='js-view-dom-id-'] > div")
      break if releases.empty?
      releases.each do |release|
        link = DOMAIN + release.css("h3 a").first["href"]
        next if @already_processed.include? link
        document,status = connect_to(link)
        next if status != 200
        date = release.css(".daterange time").first["datetime"].split("T").first.to_date rescue nil
        title = release.css("h3").first.text.strip 
        link_parser(document,title,data_source_url,date,link)
      end
      NIST.insert_all(@data_array) if !@data_array.empty?
      break if @data_array.count < releases.count
      @data_array = []
      page_no += 1
    end
  end

  def link_parser(document,title,data_source_url,date,link)
    lang_tag = document.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and lang_tag != "en"
    
    subtitle = document.css(".nist-block h3").first.text.strip rescue nil
    subtitle = subtitle == "" ? nil : subtitle
    article  = fetch_article(document)
    contact_info = document.css(".nist-block.nist-block--contact").first
    unless contact_info.nil?
      contact_info = contact_info.to_s
    end
    teaser = fetch_teaser(article,dirty_news)

    with_table = article.css("table").empty? ? 0 : 1
    tags = document.css('.nist-tags a').map{|e| e.text.strip}

    unless tags.empty?
      tags_table_insertion(tags,link)
    end

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
      data_source_url: data_source_url,
    }
    @data_array.push(data_hash)
  end

  def tags_table_insertion(tags,link)
    tags.each do |tag|
      unless @inserted_tags.include? tag
        NISTTags.insert(tag: tag)
        @inserted_tags.push(tag)
      end
      id = NISTTags.where(:tag => tag).pluck(:id)
      NISTTALinks.insert(tag_id: id[0], article_link: link)
    end
  end

  def fetch_article(document)
    article = document.css("#block-nist-www-content").first
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("script").remove
    article
  end

  def fetch_teaser(article,dirty_news)
    teaser = nil
    return teaser if dirty_news == 1
    article = article.css('.text-with-summary').first
    article.css("*").each do |node|
      next if node.text.squish == ""
      next if node.text.squish[-5..-1].nil?
      if node.text.squish.length > 100
        teaser = node.text.squish
        break
      end
    end
    
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.css("*").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      if data_array.empty?
        data_array.push(article.to_s)
      end
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser == ""
        next if teaser[-2..-1].nil?
        if teaser.length > 100
          break
        end
      end
    end

    teaser_temp = teaser

    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end

    if teaser.length  < 80
      teaser = teaser_temp[0..600].split
      dot = teaser.select{|e| e.include? ":"}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end

    if teaser.length  < 20
      teaser = nil
      return teaser
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
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('‒', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-', 2).last.strip
      end
    elsif teaser[0..18].upcase.include? 'WASHINGTON' and  teaser[0..10].include? '('
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
