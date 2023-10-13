require_relative '../models/us_dot'

class Parser <  Hamster::Scraper

  MAIN_URL = "https://www.transportation.gov"
  SOURCE = "https://www.transportation.gov/newsroom/press-releases?field_effective_date_value=01/20/2021&field_effective_date_value_1=&keys=&field_mode_target_id=All&page="
  SOURCE_ARCHIVE = "https://www.transportation.gov/newsroom/news-archive?field_effective_date_value=01/01/2010&field_effective_date_value_1=01/19/2021&combine=&page="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsDot.pluck(:link)
  end

  def connect_to(url)
    begin
      response = Hamster.connect_to(url: url,proxy_filter: @proxy_filter)
      reporting_request(response)
    end until response&.status == 200
    response
  end

  def press_release_scraper
    page_number = 0
    flag = false
    while true
      
      puts "Processing Page No #{page_number}".yellow

      data_source_url = "#{SOURCE}#{page_number}"

      response = connect_to(data_source_url)

      reporting_request(response)

      @document = Nokogiri::HTML(response.body)

      if @document.css("div.list_pagination").text.include? "There are no results to display."
        puts "No More Data Available".red
        break
      end

      flag = press_release_parser(data_source_url, flag)
      break if flag == true
      page_number +=1
    end
  end

  def news_archive_scraper
    page_number = 0
    
    while true
      puts "Processing Page No #{page_number}".yellow

      data_source_url = "#{SOURCE_ARCHIVE}#{page_number}"

      puts "#{data_source_url}".red

      response = connect_to(data_source_url)

      reporting_request(response) 

      @document = Nokogiri::HTML(response.body)

      if @document.css("div.list_pagination").text.include? "There are no results to display."
        puts "No More Data Available".red
        break
      end
      news_archive_parser(data_source_url)

      page_number +=1
    end
  end

  def press_release_parser(data_source_url, flag)
    all_links = @document.css('div.list_news article').map{|e| e.css("a.node__link")[0]['href']}
    all_teasers = @document.css('div.list_news article').map{|e| e.css("div.node__body")rescue "-"}

    press_release_data = []

    all_links.each_with_index do |link, record_number|
      article_link = "#{MAIN_URL}#{link}"
      break if @already_fetched_articles.include? article_link
      
      teaser = fetch_teaser(all_teasers[record_number])
      article_data = fetch_article(article_link)
      
      data_hash = {}  
      data_hash[:title] = article_data.css("span.field--name-title").text.squish
      data_hash[:teaser] = teaser
      data_hash[:link] = article_link
      data_hash[:date] = @document.css('div.list_news article')[record_number].css("time.datetime")[0]['datetime']
      data_hash[:article] = article_data.css("article .mb-4.clearfix").to_s 
      data_hash[:data_source_url] = data_source_url
      data_hash[:scrape_frequency] = 'daily'
      data_hash[:created_by] = 'Adeel'
      press_release_data << data_hash
    end
    
    UsDot.insert_all(press_release_data) if !press_release_data.empty?
    flag = true if press_release_data.count < 10
    press_release_data = []
    flag
  end

  def news_archive_parser(data_source_url)
    all_links = @document.css("div.list_news div.views-field-title").map{|e| e.css("h2.title--news-item a")[0]['href'] rescue  "-"}
    all_dates = @document.css("div.list_news div.views-field-field-effective-date").map{|e| Date.parse(e.css("div.field-content").text.strip) rescue "-"}
    all_teasers = @document.css("div.list_news div.views-field-body").map{|e| e.css("div.field-content") rescue "-"}

    archived_news_data = []

    all_links.each_with_index do |link, record_number|
      article_link = "#{MAIN_URL}#{link}"
      next if @already_fetched_articles.include? article_link

      teaser = fetch_teaser(all_teasers[record_number])
      article_data = fetch_article(article_link)
        
      data_hash = {}
      data_hash[:title] = article_data.css("span.field--name-title").text.squish
      data_hash[:teaser] = teaser
      data_hash[:link] = article_link
      data_hash[:date] = all_dates[record_number]
      data_hash[:article] = article_data.css("div.clearfix")[1].to_s
      data_hash[:data_source_url] = data_source_url
      data_hash[:scrape_frequency] = 'daily'
      data_hash[:created_by] = 'Adeel'
      archived_news_data << data_hash
    end
    
    UsDot.insert_all(archived_news_data) if !archived_news_data.empty?
    archived_news_data = []
  end

  def remove_dash(teaser)
    if teaser[0..100].include? '–' 
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..100].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..100].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON" or teaser[0..50].include? "TOKYO"
        teaser = teaser.split('-', 2).last.strip
      end 
    end
    teaser
  end

  def fetch_teaser(teaser_html)
    data_array = []
    teaser_html.css('p').each do |teaser|
      next if teaser.text.strip == "" or teaser.text.strip == "..."
      data_array << remove_dash(teaser.text.strip)
    end
    data_array = data_array.count > 0 ? data_array.join("\n") : "-"
    data_array
  end

  def fetch_article(link)
    puts "Processing article -> #{link}".yellow
    response = connect_to(link)
    article_data = Nokogiri::HTML(response.body)
    article_data.css('img').remove
    article_data.css('iframe').remove
    article_data.css('script').remove
    article_data.css("#block-transpo-content")
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
