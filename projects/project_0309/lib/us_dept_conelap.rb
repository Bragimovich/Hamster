# frozen_string_literal: true

require_relative '../models/db_handler'

class Scraper <  Hamster::Scraper

  URL = "https://www.help.senate.gov/chair/newsroom/press?PageNum_rs="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = UsDeptConelap.pluck(:link)
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
    article = document.css('#press').css('p')
    if article.empty?
      if document.css('#press').css('div').count > 3
        return document.css('#press').css('div')[1..-1]
      else
        return document.css('#press').css('h1').first.next_sibling rescue nil
      end
    end
    return article
  end

  def fetch_teaser(article)
    teaser = nil
    outer_teaser = ''

    article.children.each do |node|
      next if node.text.squish == ""
      next if node.parent.values.include? 'center'
      begin
        if (node.text.squish.size < 10 or node.text.squish == '.' or node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
          if outer_teaser != ''
            outer_teaser = outer_teaser + " " + node.text.squish  
          end
          teaser = node.text.squish
          break
        else
          outer_teaser = outer_teaser + " " + node.text.squish
        end
      rescue Exception => e
        puts e
      end
    end

    outer_teaser = outer_teaser.squish
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      if data_array.empty?
        teaser = article.text.squish
      end
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

  def fetch_contact_info(document)
    begin
      contact_info = ''
      if document.css('h3').count == 1 and document.css('h3').text.include? 'Contact'
        contact_info = document.css('h3').first
        if contact_info.next_sibling.name == 'p' or contact_info.next_sibling.name == 'text'
          while true
            if !contact_info.next_sibling.nil? and (contact_info.next_sibling.name == 'p' or contact_info.next_sibling.name == 'text')
              contact_info.add_child(contact_info.next_sibling)
            else
              break
            end
          end
        else
          contact_info.add_child(contact_info.next_sibling)
        end
        return contact_info
      else
        return nil
      end
    rescue Exception => e
      puts "Check Contact Info -> #{e.full_message}"
    end
  end

  def parser(body, url)
    data_array = []
    all_links = body.css('ul.PageList li').map { |e| e.css('a')[0]['href']}
    all_links.each do |link|
      unless link.include? 'https://www.help.senate.gov'
        link = 'https://www.help.senate.gov' + link
      end
      next if @already_processed.include? link
      document = connect_to(link)
      return if document.title.include? '404'
      title = document.css('span.Heading__title').text
      date = document.css('time.Heading--time')[0]['datetime'].to_date
      dirty_news = (document.css('html').attribute('lang').text.include? "en") ? 0 : 1
      article = document.css('.RawHTML')
      with_table = article.css("table").empty? ? 0 : 1
      teaser = fetch_teaser(article)
      contact_info = document.css('p.text-center').to_s
      data_hash = {
        title: title,
        teaser: teaser,
        article: article.to_s,
        date: date,
        link: link,
        dirty_news: dirty_news,
        with_table: with_table,
        data_source_url: url,
        contact_info: contact_info
      }
      data_array.push(data_hash)
      handler(UsDeptConelap, data_hash)
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

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
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
    puts "Tags Inserted"
  end

  def scraper
    page_no = 1
    @flag = false
    while true 
      url = URL + page_no.to_s + "&"
      body = connect_to(url)
      parser(body , url)
      break if @flag
      page_no += 1
    end
    puts " ------------------- script ended ------------------- "
  end
end
