# frozen_string_literal: true

require_relative '../models/db_handler'
require_relative '../models/db_handler2'
require_relative '../models/db_handler3'
require_relative '../models/db_handler4'
require_relative '../models/db_handler5'

class Scraper <  Hamster::Scraper

  URL = "https://www.dhs.gov/all-news-updates?combine=&created=&field_news_type_target_id=All&field_taxonomy_topics_target_id=All&items_per_page=10&sort_bef_combine=created_DESC&sort_by=created&sort_order=DESC&page="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = UsDeptHssat.pluck(:link)
    @processed_categories = HssatCategory.pluck(:category)
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
  end

  def fetch_article(document)
    document.css("img").remove
    document.css("iframe").remove
    document.css("figure").remove
    document.css("script").remove
    article = document.css('div.field.field--name-body.field--type-text-with-summary.field--label-hidden.field__item').first
    return article
  end

  def fetch_teaser(article)
    teaser = nil
    article.children.each do |node|
      next if node.text.squish[-3..-1].nil?
      next if node.text.squish == ""
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
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
          break
        end
      end
    end
    if teaser == ""
      teaser = article.text.squeeze
    end
    full_teaser = teaser
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      if dot == ['D.C.']
        teaser = teaser.join(" ")+":"
      else
        dot = dot.uniq
        ind = teaser.index dot[-1]
        teaser = teaser[0..ind].join(" ")
        if teaser.length < 80
          teaser = full_teaser[0..600]+":"  
        end
      end
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
    end
    teaser
  end

  def get_contact_info(article)
    if !article.css('h3').nil? and article.css('h3').text.upcase.include? 'FOR IMMEDIATE RELEASE'
      contact_info = article.css('h3').first
      article.replace(contact_info)
      return [article, contact_info]
    elsif article.css('p').count != 0 and article.css('p').first.text.upcase.include? 'FOR IMMEDIATE RELEASE'
      contact_info = article.css('p').first
      article.replace(contact_info)
      return [article, contact_info]
    else
      return [article, nil]
    end
  end

  def fetch_category(document)
    return document.css('ul.usa-collection__meta.clearfix').select{|e| e.text.downcase.include? "topics"}.first.css(".usa-tag").map{|e| e.text} rescue nil
  end

  def fetch_tags(document)
    return document.css('ul.usa-collection__meta.clearfix').select{|e| e.text.downcase.include? "keywords"}.first.css(".usa-tag").map{|e| e.text} rescue nil
  end

  def parser(body, url)
    all_links = body.css('div[class="news-updates views-row"]').map{|e| [e.css('div[class="news-updates-date-type"]').css('span')[0].text.strip, e.css('h3').text.strip, "https://www.dhs.gov"+e.css('h3 a')[-1]['href']]}
    data_array = []
    all_links.each_with_index do |data , ind|
      next if @already_processed.include? data[-1]
      date = data[0]
      title = data[-2]
      link = data[-1]
      document = connect_to(link)
      if document.css('article')[0].attr('lang').nil?
        dirty_news = 0
      else
        dirty_news = (document.css('article')[0].attr('lang').include? "en") ? 0 : 1
      end
      article = fetch_article(document)
      article, contact_info = get_contact_info(article)
      with_table = article.css("table").empty? ? 0 : 1
      teaser = fetch_teaser(article)
      data_hash = {
        title: title,
        teaser: teaser,
        article: article.to_s,
        date: date,
        link: link,
        contact_info: contact_info.to_s,
        dirty_news: dirty_news,
        with_table: with_table,
        data_source_url: url
      }
      data_array.push(data_hash)
      handler(UsDeptHssat, data_hash)
      category = fetch_category(document)
      if !category.nil?
        all_categories = category.map(&:strip)
        all_categories.each do |category|
          data_hash = {}
          data_hash[:category] = category
          category_id = handler2(HssatCategory, data_hash)
          data_hash = {}
          data_hash[:category_id] = category_id
          data_hash[:article_link] = link
          handler(HssatCategoryArticleLinks, data_hash)  
        end
      end
      all_tags = fetch_tags(document)
      if !all_tags.nil?
        all_tags.each do |tag|
          data_hash = {}
          data_hash[:tag] = tag
          handler(HssatTags, data_hash)
          tag_id = handler3(HssatTags, data_hash)
          data_hash = {}
          data_hash[:tag_id] = tag_id
          data_hash[:article_link] = link
          handler(HssatTagsArticleLinks, data_hash)
        end
      end
    end
    @flag = true if all_links.count > data_array.count
  end

  def handler(db_object, data_hash)
    begin
      db_object.insert(data_hash)
    rescue Exception => e
      puts "mysql error -> #{e.full_message}"
    end
  end

  def handler2(db_object, data_hash)
    begin
      return db_object.where(:category => data_hash[:category]).pluck(:id)[0]
    rescue Exception => e
      puts "mysql error -> #{e.full_message}"
    end
  end

  def handler3(db_object, data_hash)
    begin
      return db_object.where(:tag => data_hash[:tag]).pluck(:id)[0]
    rescue Exception => e
      puts "mysql error -> #{e.full_message}"
    end
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end

  def category_handler(body)
    category_values = body.css('#edit-field-taxonomy-topics-target-id').css('option').map(&:values)[1..-1].flatten
    category_texts = body.css('#edit-field-taxonomy-topics-target-id').css('option').map(&:text)[1..-1].flatten

    category_texts.each do |category|
      next if @processed_categories.include? category
      data_hash = {}
      data_hash[:category] = category
      handler(HssatCategory, data_hash)
    end
    return category_values
  end

  def scraper
    page_no = 0
    category_flag = true
    @flag = false
    while true
      url = URL + page_no.to_s
      body = connect_to(url)
      if category_flag
        category_handler(body)
        category_flag = false
      end
      parser(body, url)
      break if @flag
      page_no += 1
    end    
  end
end
