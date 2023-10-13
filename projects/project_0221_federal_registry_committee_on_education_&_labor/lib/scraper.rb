# frozen_string_literal: true

require_relative '../models/us_dept_celr'
require_relative '../models/us_dept_celr_tags'
require_relative '../models/us_dept_celr_tags_article_links'

class Scraper <  Hamster::Scraper

  URL = "https://edworkforce.house.gov/news/documentquery.aspx?DocumentTypeID=1823&Page="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed_tags = CelrTags.pluck(:tag)
    @already_processed = Celr.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def scraper
    @flag = false
    page_no = 1
    while true
      break if @flag
      url = URL + page_no.to_s
      body = connect_to(url)
      break if body.css("#newsdoclist").text.squish == ""
      parser(body, url) 
      page_no += 1   
    end    
  end

  def parser(body , url) 
    array = []
    all_links = body.css("#newsdoclist article").map{|e| "https://edworkforce.house.gov/news/" + e.css("div.news-texthold .newsie-titler a").attr("href").value rescue nil}
    dates = body.css("#newsdoclist article").map{|e| e.css("div.newsie-details time").text.squish rescue nil}
    all_links.each_with_index do |link , ind|
      next if link.nil? or  @already_processed.include? link
      document = connect_to(link)
      article_body = document.css("#ctl00_ctl25_ControlBody")
      dirty_news = (document.css("*").attr("lang").value.include? "en") ? 0 : 1
      title = article_body.css("div.single-headline .newsie-titler").text.squish
      date = Date.parse(dates[ind]) rescue nil 
      article = fetch_article(article_body)
      with_table = article.css("table").empty? ? 0 : 1
      teaser = fetch_teaser(article,document)
      tags_handler(article_body , link)
      data_hash = {
        title: title,
        teaser: teaser,
        article: article.to_s,
        date: date,
        link: link,
        dirty_news: dirty_news,
        with_table: with_table,
        data_source_url: url
      }
      array.push(data_hash)
    end
    Celr.insert_all(array) if !array.empty?
    @flag = true if array.count != all_links.count
  end

  def tags_handler(article_body , link)
    return if article_body.css("#ctl00_ctl25_CatTags").empty?
    tags = article_body.css("#ctl00_ctl25_CatTags em").map{|e| e.text.squish}
    return if tags.empty?
    tags.each do |tag|
      if @already_processed_tags.include? tag
        tag_id = CelrTags.where(:tag => tag).pluck(:id).first
        data_hash2 = {
          tag_id: tag_id,
          article_link: link
        }  
        CelrTagsArtcile.insert(data_hash2)   
      else
        data_hash = {
          tag: tag
        }
        CelrTags.insert(data_hash)
        tag_id = CelrTags.where(:tag => tag).pluck(:id).first
        data_hash2 = {
          tag_id: tag_id,
          article_link: link
        }  
        CelrTagsArtcile.insert(data_hash2) 
      end
    end
  end

  def fetch_article(document)
    document.css("img").remove
    document.css("iframe").remove
    document.css("figure").remove
    document.css("script").remove
    article = document.css(".main-newscopy .bodycopy").first
    article
  end

  def fetch_teaser(article,document)
    teaser = nil
    article.children.each do |node|
      next if node.text.squish == ""
        if (node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
          teaser = node.text.squish
          break
        else document.css("div.bodycopy").text.split("\r\n")[1].squish.length > 50 and (document.css("div.bodycopy").text.split("\r\n")[1].squish[-5..-1].include? "." or document.css("div.bodycopy").text.split("\r\n")[1].squish[-5..-1].include? ":")
          teaser = document.css("div.bodycopy").text.split("\r\n")[1].squish
          break
        end
    end
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
          break
        end
      end
    end
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
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-' , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end
end
