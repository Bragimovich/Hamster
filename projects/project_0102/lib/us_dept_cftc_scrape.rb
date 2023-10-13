require_relative '../models/us_dept_cftc'

class UsDeptCftcScrape <  Hamster::Scraper

  MAIN_URL = "https://www.cftc.gov"
  SOURCE = "https://www.cftc.gov/PressRoom/PressReleases?combine=&field_press_release_types_value=All&field_release_number_value=&prtid=All&year=all&page="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsDeptCftc.pluck(:link)
  end
  
  def connect_to(url)
    retries = 0

    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def press_release_scraper
    page_number = 0
    flag = false
    
    while true
      puts "Processing Page No #{page_number}".yellow
      data_source_url = "#{SOURCE}#{page_number}"
      @document = connect_to(data_source_url)
      flag = press_release_parser(data_source_url, flag)
      break if flag == true
      page_number +=1
    end
  end

  def get_teaser(parsed_object)
   teaser = nil 
    parsed_object.css('article div.field--name-body p').map do |node|
      next if node.text.squish == ""
      if (node.text.squish[-3..-1].include? "." or node.text.squish[-3..-1].include? ":" or node.text.squish[-3..-1].include? "]") and node.text.squish.length > 100
        teaser = node.text.squish
        break
      end
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
    elsif teaser[0..50].include? "\u0096"
      teaser = teaser.split("\u0096", 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON" or teaser[0..50].include? "TOKYO"
        teaser = teaser.split('-', 2).last.strip
      end
    end
    teaser
  end
  
  def press_release_parser(data_source_url, flag)
    press_release_data = []
    all_links =  @document.css("div.view-content table tbody tr").map{|e| e.css("td[2] a")[0]['href'] rescue nil}
    all_dates = @document.css("div.view-content table tbody tr").map{|e| e.css("td[1] time")[0]['datetime'] rescue nil }
    
    all_links.each_with_index do |link, ind|
      article_link = "#{MAIN_URL}#{link}"   
      break if @already_fetched_articles.include? article_link
      article_data = fetch_article(article_link)
      next if article_data.nil? or article_data.empty?
      article_data.css('img').remove
      article_data.css('figure').remove
      article_data.css("script").remove
      
      data_hash = {
        release_no: article_data.css("h1.press-release-title").text.split[-1],
        title:  article_data.css("h1").last.text,
        teaser: get_teaser(article_data),
        article: article_data.css("div.field--name-body").to_s,
        link: article_link,
        date:  all_dates[ind].split("T").first,
        data_source_url: data_source_url
      }
      press_release_data.push(data_hash)
    end
    
    UsDeptCftc.insert_all(press_release_data) if !press_release_data.empty?
    flag = true if press_release_data.count < all_links.count
    flag
  end

  def fetch_article(link)
    @article_details = connect_to(link)
    @article_details.css("img").remove
    @article_details.css("iframe").remove
    @article_details.css("figure").remove
    @article_details.css("div#content-container section article")
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
