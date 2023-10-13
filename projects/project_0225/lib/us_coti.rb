# frozen_string_literal: true

require_relative '../models/db_handler'

class Scraper <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = DbHandler.pluck(:link)
  end

  def scraper
    @flag = false
    page_no = 1
    url = "https://transportation.house.gov/news/documentquery.aspx?Year=#{Date.today.year}&Page="
    while true
      main_url = "#{url}#{page_no.to_s}"
      body = connect_to(main_url)
      parser(body, main_url)
      break if @flag
      page_no += 1
    end    
  end

  private

  def parser(body, url)
    array = []
    all_links = body.css('.UnorderedNewsList li').map{|e| "https://transportation.house.gov/news/"+e.css('a')[0]['href']}
    all_links.each_with_index do |link, ind|
      next if @already_processed.include? link
      document = connect_to(link)
      dirty_news = (document.css("*").attr("lang").value.include? "en") ? 0 : 1
      title = document.css('h3[class="middleheadline"]').text.squish 
      date = Date.parse(document.css('.topnewsbar').text.squish).to_date rescue nil
      article = fetch_article(document)
      subtitle = fetch_subtitle(article, title)
      with_table = article.css("table").empty? ? 0 : 1
      contact_info = get_contact_info(document)
      teaser = fetch_teaser(article)
      teaser unless teaser.nil?
      data_hash = {
        title: title,
        subtitle: subtitle,
        teaser: teaser,
        article: article.to_s,
        date: date,
        link: link,
        contact_info: contact_info.to_s,
        dirty_news: dirty_news,
        with_table: with_table
      }
      array.push(data_hash)
    end
    DbHandler.insert_all(array) unless array.empty?
    @flag = true if all_links.count > array.count 
  end

  def get_contact_info(document)
    if document.text.squish.include? 'Contact'
      contact_info = document.css(".topnewstext") rescue nil
      unless (contact_info.nil? and contact_info.text.size < 20)
        mail = document.css(".topnewstext a").first.to_s
        information = contact_info.text.squish.split('|')
        number = information[1].split('e')
        contact_number = number[2].squish
        contact_info = "#{mail}#{contact_number}"
      end
    end
    contact_info
  end

  def fetch_subtitle(article, title)
    if article.css('em').reject{|e| e.text.length < 30}.count != 0
      subtitle = article.css('em').reject{|e| e.text.length < 30}[0].text
      begin
        if !subtitle.nil? and ((article.text.index subtitle.split()[0]) - (article.text.index title.split[-1])) > 20
          return article.css('p[align="center"]').map(&:text).map(&:strip).reject(&:empty?)[0]
        else
          return article.css('em').reject{|e| e.text.length < 30}[0].text
        end
      rescue
        nil
      end
    end

    if article.css('p[align="center"]').map(&:text).map(&:strip).reject(&:empty?).count != 0
      if article.css('h3[align="center"]').count == 1
        article.css('h3[align="center"]').map(&:text).map(&:strip).reject(&:empty?)[0]
      else
        article.css('p[align="center"]').map(&:text).map(&:strip).reject(&:empty?)[0]
      end
    end
    nil
  end

  def fetch_article(document)
    article = document.css(".bodycopy")
    remove_unnecessary_tags(article, %w[img iframe figure script])
    article
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_teaser(article)
    teaser = nil
    article.children.each do |node| 
      next if node.text.squish == ""
      begin
        if (node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
          teaser = node.text.squish
          break
        end
      rescue
        nil
      end 
    end

    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""
        if (teaser[-5..-1].include? "." or teaser[-5..-1].include? ":") and teaser.length > 50
          break
        end
      end
    end

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

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
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
