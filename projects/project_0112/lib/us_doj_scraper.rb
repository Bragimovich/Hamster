# frozen_string_literal: true

require_relative '../models/us_doj'

class UsDojScraper <  Hamster::Scraper

  MAIN_URL = "https://www.justice.gov"
  SOURCE = "https://www.justice.gov/news?f%5B0%5D=type%3Apress_release&page="
  
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsDoj.pluck(:link)
  end

  def press_release_scraper
    page_number = 0
    @flag = false

    while true
      puts "Processing Page No #{page_number}".yellow
      data_source_url = "#{SOURCE}#{page_number}"
      @document = connect_to(data_source_url)
      press_release_parser(data_source_url)
      break if @flag == true
      page_number +=1
    end
  end

  private

  def press_release_parser(data_source_url)
    press_release_data = []
    all_links = @document.css("div.view-content div.views-field.views-field-title").map{|e| e.css("span.field-content a")[0]['href']}
    all_links.each do |link|
      article_link = "#{MAIN_URL}#{link}"
      next if @already_fetched_articles.include? "#{article_link}"

      fetch_article(article_link)
      press_release_data << data_parser(data_source_url, article_link)
    end
    UsDoj.insert_all(press_release_data) if !press_release_data.empty?
    return @flag = true if press_release_data.count < all_links.count
  end

  def data_parser(data_source_url, article_link)
    data_hash = {}
    article = @article_data.css("article div.node__content div.field--name-field-pr-body div.field__items")
    data_hash[:title] = @article_data.css("h1#node-title").text.squish
    data_hash[:subtitle] = @article_data.css("h2#node-subtitle").text.squish rescue nil
    data_hash[:teaser] = fetch_teaser(article)
    data_hash[:link] = article_link
    data_hash[:article] = article.to_s
    data_hash[:release_no]  = @article_data.css("div.pr-fields div.field--name-field-pr-number div.field__items").text
    data_hash[:components] = fetch_components
    data_hash[:data_source_url] = data_source_url
    data_hash[:date] = @article_data.css("div.pr-info div.field--name-field-pr-date div.field__item span.date-display-single")[0]['content']
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end

  def fetch_components
    components_count = @article_data.css("div.pr-fields div.field--name-field-pr-component div.field__items div.field__item").count
    data = @article_data.css("div.pr-fields div.field--name-field-pr-component div.field__items div.field__item")
    all_data = []
    (0...components_count).each do |ind|
      all_data << data[ind].text
    end
    all_data.to_json
  end

  def fetch_teaser(article)
    teaser = nil
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
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end
    return nil if teaser.length  < 20
    teaser[-1] = '...' if teaser[-1].include? ":"
    teaser = cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('‒' , 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-' , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
        teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end

  def fetch_article(link)
    @article_data = connect_to(link)
    @article_data.css("img").remove
    @article_data.css("figure").remove
    @article_data.css("iframe").remove
    @article_data.css("script").remove
    @article_data
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    Nokogiri::HTML(response.body)
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
