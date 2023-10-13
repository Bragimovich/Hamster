# frozen_string_literal: true

require_relative '../models/db_handler'
require_relative '../models/db_handler2'
require_relative '../models/db_handler3'
require_relative '../models/db_handler4'
require_relative '../models/db_handler5'

class Scraper <  Hamster::Scraper

  URL = 'https://www.noaa.gov/media-releases?page='
  BASE_URL = 'https://www.noaa.gov/media-releases'
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
    super
    @proxy_filter            = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @already_processed       = UsDeptNoaa.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      next if (response.nil?)
      if [301, 302].include? response&.status
        url = response.headers["location"]
        puts "URL is redirected to -> #{url}".yellow
        response = Hamster.connect_to(url:  url , proxy_filter: @proxy_filter)
      end
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    Nokogiri::HTML(response.body)
  end

  def fetch_article(document)
    document.css('img').remove
    document.css('iframe').remove
    document.css('figure').remove
    document.css('script').remove
    document.css(".text-formatted p")[0...-1] 
  end

  def fetch_teaser(article)
    teaser = nil
    article.each do |node|
      next if node.text.squish.empty? or node.text.squish[-3..].nil?

      if (node.text.squish[-3..].include? '.' or node.text.squish[-3..].include? ':') and node.text.squish.length > 50
        teaser = node.text.squish
        break
      end
    end

    if teaser == '-' or teaser.nil? or teaser.empty?
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser.empty?

        break if (teaser[-2..].include? '.' or teaser[-2..].include? ':') and teaser.length > 50

      end
    end
    if teaser.nil? or teaser.empty? or teaser == '-'
      teaser = TeaserCorrector.new(article.text.squish).correct.strip
    else
      teaser = TeaserCorrector.new(teaser).correct.strip
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
      if teaser[0..50].include? 'Washington' or teaser[0..50].include? 'WASHINGTON'
        teaser = teaser.split('-', 2).last.strip
      end
    end
    teaser
  end

  def get_contact_info(document)
    contact_info = nil
    data = document.css('div[class = "field field--name-field-email field--type-email field--label-hidden field__item"]')
    unless data.count == 0
      if data.text.squish.size > 350
        return nil
      else
        return data

      end
    else
      article = document.css('div[class="field field--name-field-body-formatted-long field--type-text-long field--label-hidden"]')
      if article.text.downcase.squish.include? 'Media contact'.downcase or article.text.downcase.squish.include? 'contact:'.downcase
        contact_info = article.css('p').select{|e| e.text.upcase.include? 'media Contact'.upcase or e.text.upcase.include? 'contact:'.upcase}.first rescue nil
        if contact_info.nil?
          contact_info = article.css('div').select{|e| e.text.upcase.include? 'media Contact'.upcase or e.text.upcase.include? 'contact:'.upcase}.last rescue nil
        end
        if !contact_info.nil? and contact_info.text.size < 20
          while true
            begin
              if !contact_info.next_element.nil? and (contact_info.next_element.name == 'div' or contact_info.next_element.name == 'p' or contact_info.next_element.name =='h3')
                if !contact_info.next_element.children.nil? and (contact_info.next_element.children.select{|e| e.name =='b' or e.name=='strong'}.count != 0)
                  break

                else
                  contact_info.add_child(contact_info.next_element)
                end
              else
                break

              end
            rescue Exception => e
              puts "check Contact Info Exception -> #{e.full_message}"
            end
          end
        elsif !contact_info.nil? and contact_info.text.size > 300
          contact_info = document.css('address').select{|e| e.text.upcase.include? 'contact:'.upcase}.first rescue nil
          unless contact_info.nil? and contact_info.text.size > 20
            while true
              if !contact_info.next_element.nil? and (contact_info.next_element.name == 'address')
                if !contact_info.next_element.children.nil? and (contact_info.next_element.children.text.squish.empty?)
                  break

                else
                  contact_info.add_child(contact_info.next_element)
                end
              end
            end 
          end
        end
      else
        contact_info = nil
      end
    end
    contact_info
  end

  def fetch_category(document)
    document.css('.views-row').map{|e| [e.css('.focus-areas .field .field__items').text.squish, e.css('.field__item a')[0]['href']] }
  end

  def fetch_tags(document)
    document.css('.views-row').map{|e| [e.css('div.tags').css('div.topic-tags').css('div.field__item').map(&:text).map(&:strip).first, e.css('.field__item a')[0]['href']]} rescue []
  end

  def fetch_subtitle(document)
    unless document.css('h2[class="node-subtitle field"]').count == 0
      return document.css('h2[class="node-subtitle field"]').text.squish

    else
      unless document.css('p[class="lead"]').count == 0
        return document.css('p[class="lead"]').text.squish

      else
        return nil

      end
    end
  end

  def parser(body)
    data_array   = []
    all_articles = body.css('div[class="view__content"]').css('article')
    all_articles.each_with_index do |row, ind|
      link = 'https://www.noaa.gov' + row.css('div[class="title"] a')[0]['href']
      next if @already_processed.include? link

      title = row.css('div[class="content-wrapper"]').css('div.title').text.squish
      next if title.include? 'TEST Media Release'
      
      date = row.css('div[class="content-wrapper"]').css('div.date').text.squish
      document = connect_to(link)
      next if document.title.include? 'Redirecting to'
      all_categories = fetch_category(body)
      unless all_categories.nil? or all_categories.empty?
        all_categories.each do |category|
          data_hash = {}
          data_hash[:category] = category[0]
          handler(UsDeptNoaaCategories, data_hash)
          category_id = handler2(UsDeptNoaaCategories, data_hash)
          data_hash   = {}
          data_hash[:category_id]  = category_id
          data_hash[:article_link] = 'https://www.noaa.gov' + category[1]
          handler(UsDeptNoaaCategoriesArticleLinks, data_hash)
        end
      end

      all_tags = fetch_tags(body)
      unless all_tags.nil? or all_tags.empty?
        all_tags.each do |tag|
          data_hash = {}
          data_hash[:tag] = tag[0]
          handler(UsDeptNoaaTags, data_hash)
          tag_id = handler3(UsDeptNoaaTags, data_hash)
          data_hash = {}
          data_hash[:tag_id]       = tag_id
          data_hash[:article_link] = 'https://www.noaa.gov' + tag[1]
          handler(UsDeptNoaaTagsArticleLinks, data_hash)
        end
      end

      dirty_news   = (document.css('html').attribute('lang').text.include? "en") ? 0 : 1
      article      = fetch_article(document)
      subtitle     = fetch_subtitle(document)
      contact_info = get_contact_info(document)
      with_table   = article.css('table').empty? ? 0 : 1
      teaser       = fetch_teaser(article)
      article      = article.nil? ? nil : article.to_s
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
        with_table: with_table
      }
      handler(UsDeptNoaa, data_hash)
      data_array.push(data_hash)
    end
    @flag = true if all_articles.count > data_array.count
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
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end

  def scraper
    page_no   = 1
    base_flag = true
    @flag     = false
    while true
      if base_flag
        body      = connect_to(BASE_URL)
        base_flag = false
      else
        url  = URL + page_no.to_s
        body = connect_to(url)
      end
      parser(body)
      break if @flag

      page_no += 1
    end
  end
end
