# frozen_string_literal: true
require_relative '../models/db_handler'
require_relative '../models/db_handler2'
require_relative '../models/db_handler3'

class Scraper <  Hamster::Scraper

  URL = "https://eda.gov/news/press-releases/"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = UsDeptEda.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10
    Nokogiri::HTML(response.body)
  end

  def fetch_article(document)
    document.css("img").remove
    document.css("iframe").remove
    document.css("figure").remove
    document.css("script").remove
    article = document.css('#mainContent p')
    article
  end

  def fetch_teaser(article)
    teaser = nil
    outer_teaser = ''
    article.children.each do |node|
      next if node.text.squish == ""
      if (node.text.squish == '.' or node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
        if outer_teaser != ''
          outer_teaser = outer_teaser + " " + node.text.squish  
        end
        teaser = node.text.squish
        break
      else
        outer_teaser = outer_teaser + " " + node.text.squish
      end
    end
    outer_teaser = outer_teaser.squish
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
          break
        elsif teaser.length > 100
          break  
        end
      end
    end
    teaser = outer_teaser != '' ? outer_teaser : teaser
    full_teaser = teaser
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      if dot == ['D.C.']
        teaser = teaser.join(" ")+":"
      else
        dot = dot.uniq
        all_indexes = teaser.each_index.select{|i| teaser[i] == dot[-1]}        
        teaser = teaser[0..all_indexes[-1]].join(" ")
        if teaser.size < 80
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

  def get_contact_info(document)
    contact_info = nil
    if document.css('#mainContent div').first.text.upcase.include? 'Contact:'.upcase
      contact_info = document.css('#mainContent div').first.css('br')[0].previous_sibling
      date = document.css('#mainContent div').first.css('br')[0].next_sibling.text.squish
      return [contact_info, date]
    else
      return [contact_info, nil]
    end
    [contact_info, nil]
  end

  def fetch_tags(document)
    begin
      return document.css('div.tags').css('div.topic-tags').css('div.field__item').map(&:text).map(&:strip)
    rescue Exception => e
      return ''
    end
  end

  def fetch_subtitle(document)
    if document.css('h3[style="font-style: italic\;"]').count != 0
      return document.css('h3[style="font-style: italic\;"]').text.squish
    else
      return nil
    end
  end

  def parser(body, link)
    document = connect_to(link)
    return if document.title.include? '404'
    title = document.css('#page-title').text.squish
    contact_info, date = get_contact_info(document)
    dirty_news = (document.css('html').attribute('lang').text.include? "en") ? 0 : 1
    article = fetch_article(document)
    subtitle = fetch_subtitle(document)
    with_table = article.css("table").empty? ? 0 : 1
    teaser = fetch_teaser(article)
    article = article.nil? ? nil : article.to_s
    contact_info = contact_info.nil? ? nil : contact_info.to_s
    
    data_hash = {
      title: title,
      subtitle: subtitle,
      teaser: teaser,
      article: article,
      date: date,
      link: link,
      contact_info: contact_info,
      dirty_news: dirty_news,
      with_table: with_table,
      data_source_url: link
    }
    handler(UsDeptEda, data_hash)
  end

  def handler(db_object, data_hash)
    begin
      db_object.insert(data_hash)
    rescue Exception => e
      return
    end
  end

  def tag_insertions(all_tag_texts, all_tag_links)
    tag_array = []
    all_tag_texts.each_with_index do |tag, index|
      data_hash = {}
      data_hash[:tag] = tag
      data_hash[:tag_link] = all_tag_links[index]
      tag_array << data_hash
    end
    UsDeptEdaTags.insert_all(tag_array) if !tag_array.empty?
  end

  def scraper
    url = URL
    body = connect_to(url)
    all_tag_links = body.css('#mainContent p')[1].css('a').map{|e| "https://eda.gov"+e['href']}
    all_tag_texts = body.css('#mainContent p')[1].css('a').map(&:text)
    all_links = body.css('#mainContent').css('ul').map{|s| s.css('a').map{|s| "https://eda.gov"+s['href']}}.flatten.reject{|e| e.include? 'https://www.commerce.gov/'}
    tag_insertions(all_tag_texts, all_tag_links)
    all_links.each do |link|
      next if @already_processed.include? link
      parser(body, link)
    end
  end
end
