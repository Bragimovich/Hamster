# frozen_string_literal: true

require_relative '../models/us_dept_msc'

class ScraperArchive <  Hamster::Scraper

  ARCHIVE_URL = "https://www.usmarshals.gov/news/chron/"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = Msc.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 5
    Nokogiri::HTML(response.body)
  end

  def scraper
    years = [2019 , 2020]
    years.each do |year|
      url = ARCHIVE_URL + "#{year}/"
      document = connect_to(url)
      parser(document , url)   
    end
  end

  def parser(body , url)
    array = [] 
    @flag = false
    all_links = body.css("table tr").select{|e| e.text.include? ".htm"}.map{|e| ARCHIVE_URL + e.css("td")[1].css("a").attr("href").value}
    all_dates = body.css("table tr").select{|e| e.text.include? ".htm"}.map{|e| e.css("td")[2].text.split.first.strip}  
    all_links.each_with_index do |link , ind|
      next if @already_processed.include? link
      if link.include? "scam"
        @flag = true
      end
      document = connect_to(link)
      if document.text.include? "We are sorry"
        @flag = false
        next
      end
      title = fetch_title(document)
      contact_info = fetch_contact(document)
      article = fetch_article(document)
      with_table = article.css("table").empty? ? 0 : 1
      dirty_news = (document.css("*").attr("lang").value.include? "en") ? 0 : 1 rescue 0
      teaser = fetch_teaser(article)
      date = all_dates[ind]
      data_hash = {
        title: title,
        teaser: teaser,
        article: article.to_s,
        date: date,
        link: link,
        contact_info: contact_info,
        dirty_news: dirty_news,
        with_table: with_table,
        data_source_url: url
      }
      if @flag
        @flag = false
      end 
      array.push(data_hash)
    end
    Msc.insert_all(array) if !array.empty
  end

  def fetch_title(document)
    title = nil
    if @flag
      title = document.css("table")[1].css("tr")[3].text.squish
    else
      title = document.css("table")[2].css("tr")[1].text.squish
    end
    return title
  end

  def fetch_contact(document)
    contact_info = nil 
    if @flag 
      contact_info = nil
    else  
      contact_info = document.css("table")[1].css("tr").last.css("td").last
    end
    contact_info.to_s
  end
  
  def fetch_article(document)
    document.css("img").remove
    document.css("iframe").remove
    document.css("figure").remove
    document.css("script").remove
    article = nil
    if @flag
      article = document.css("table")[1].css("tr")[-5]
    else
      article = document.css("table")[2].css("tr")[3].css("td") rescue nil 
      article = document.css("table")[2].css("tr")[2].css("td") if article.nil?
    end
    article
  end

  def fetch_teaser(article)
    teaser = nil
    article.children.each do |node|
      next if node.text.squish == "" or node.text.squish.length < 50
        if (node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
          teaser = node.text.squish
          break
        end
    end
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == "" or teaser.length < 100
        if (teaser[-5..-1].include? "." or teaser[-5..-1].include? ":") and teaser.length > 100
          break
        end
      end
    end
    #return nil if teaser.nil? or teaser == ""
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
