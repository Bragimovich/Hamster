# frozen_string_literal: true

class UsAgricultureScraper <  Hamster::Scraper

  def initialize(main_url, table_class)
    super
    @main_url                 = main_url
    @table_class              = table_class
    @proxy_filter             = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason  = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = @table_class.pluck(:link)
    @data_array               = []
  end

  def main
    page_number = 1
    document    = connect_to(@main_url + page_number.to_s)
    last_page   = document.css("#showing-page option").last.text.to_i
    while page_number <= last_page
      unless page_number == 1
        document = connect_to(@main_url + page_number.to_s)
      end
      inner_links = document.css("div.ArticleBlock a").map{|e| e["href"]}
      inner_links.each do |link|
        next if @already_fetched_articles.include? link
        document = connect_to(link)
        inner_page_parser(document,link)
      end
      @table_class.insert_all(@data_array) if !@data_array.empty?
      break if @data_array.count < inner_links.count
      @data_array = []
      page_number += 1
    end
  end

  private
  
  def inner_page_parser(document,link)
    unless document.css("*[lang]").first["lang"] == "en"
      article   = fetch_article(document)
      data_hash = {
        title: nil,
        subtitle: nil,
        teaser: nil,
        article: article.to_s,
        link: link,
        date: nil,
        with_table: nil,
        dirty_news: 1,
      }
      @data_array.push(data_hash)
      return
    end

    title      = document.css("h1.Heading__title").text.strip
    subtitle   = document.css("div.RawHTML.Paragraph.Paragraph--variant--intro p").text.strip rescue nil
    subtitle   = subtitle.split("\n").first.strip rescue nil
    date       = document.css("time").text.split(":")[1].strip.to_date
    article    = fetch_article(document)
    teaser     = document.css("div.js-press-release p").first.text.strip rescue nil
    teaser     = fetch_teaser(article)
    with_table = article.css("table").empty? ? 0 : 1
    data_hash  = {
      title: title,
      subtitle: subtitle,
      teaser: teaser,
      article: article.to_s,
      link: link,
      date: date,
      with_table: with_table,
      dirty_news: 0,
    }
    @data_array.push(data_hash)
  end

  def fetch_article(document)
    article = document.css("div.js-press-release")
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("script").remove
    article
  end

  def fetch_teaser(article)
    teaser = nil
    article.css("h1").remove
    article.css("h3").remove
    article.children.each do |node|
      next if node.text.squish.empty?
      if node.to_s.include? '<h2' and node.to_s.include? "subtitle"
        node = node.text.split("\n")[1..-1].join("\n")
        next if node.squish[-5..-1].nil?
        if (node.squish[-5..-1].include? "." or node.squish[-5..-1].include? ":" or node.squish[-5..-1].include? "-") and node.squish.length > 400
          teaser = node.squish
          break
        end
      elsif (node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
        teaser = node.text.squish
        break
      end
    end
    if teaser == '-' or teaser.nil? or teaser.empty?
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser.empty?
        break if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
      end
    end
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot    = teaser.select{|e| e.include? "."}.uniq
      ind    = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end
    return nil if teaser.empty?
    teaser[-1].include? ":" ? teaser[-1] = "..." : teaser
    cleaning_teaser(teaser)
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

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or retries == 10
    Nokogiri::HTML(response.body.force_encoding("utf-8"))
  end
end
