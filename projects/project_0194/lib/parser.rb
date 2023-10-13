# frozen_string_literal: true
class Parser < Hamster::Scraper

  DOMAIN = "https://agriculture.house.gov/news/"
  def initialize
    super
  end

  def count_links(html)
    body = Nokogiri::HTML(html)
    body.css("article h2.newsie-titler").count
  end

  def send_links(html)
    body = Nokogiri::HTML(html)
    body.css("article h2.newsie-titler").map{|e| DOMAIN + e.css("a").attr('href').value}
  end

  def parser(content, subfolder, already_fetched)
    data_array = []
    outer_content = Nokogiri::HTML(content)
    dates = outer_content.css("article div.newsie-details").map{|e| e.css("time").attr('datetime').value rescue nil}
    types = outer_content.css("article div.newsie-details").map{|e| e.css("span.cattype").children.text.split("in").last.strip rescue nil}
    send_links(content).each_with_index do |link, ind|
      next if already_fetched.include? link
      file_name = Digest::MD5.hexdigest link
      body = peon.give(file:file_name, subfolder:subfolder)
      parsed_content = Nokogiri::HTML(body)
      data_array << prepare_hash(parsed_content, dates[ind], types[ind], link)
    end
    data_array
  end

  def prepare_hash(parsed_content, date,type, link)
    article = fetch_article(parsed_content)

    with_table = article.css("table").empty? ? 0 : 1
    dirty_news = (parsed_content.css('html').attribute('lang').text.include? "en") ? 0 : 1
    teaser = fetch_teaser(article)

    data_hash = {
      title: parsed_content.css("div.single-headline").text.squish,
      teaser: teaser,
      article: article.to_s,
      date: date,
      link: link,
      dirty_news: dirty_news,
      with_table: with_table,
      type: type.downcase
    }
    data_hash
  end

  def fetch_article(document)
    document.css("img").remove
    document.css("iframe").remove
    document.css("figure").remove
    article = document.css('div.main-newscopy .newsbody').first
    article
  end

  def fetch_teaser(article)
    teaser = nil

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
    if teaser.nil? or teaser == '' or teaser == '-'
      teaser = TeaserCorrector.new(article.text.squish).correct.strip
    else
      teaser = TeaserCorrector.new(teaser).correct.strip
    end
    teaser = cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '?'
      teaser = teaser.split('?', 2).last.strip
    elsif teaser[0..50].include? '?'
      teaser = teaser.split('?', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('?', 2).last.strip
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
end