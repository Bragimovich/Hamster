require_relative '../models/us_itc'

class UsItcScraper <  Hamster::Scraper

  SOURCE  = "https://www.usitc.gov/news_releases?page="
  MAIN_URL = "https://www.usitc.gov"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_links = UsItc.pluck(:link)
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

  def main_scraper
    page_number = 0
    @flag = false

    while true
      puts "Processing Page No #{page_number}".yellow
      data_source_url = "#{SOURCE}#{page_number}"
      document = connect_to(data_source_url)
      main_page_parser(document, data_source_url)
      break if @flag == true
      page_number +=1
    end
  end

  def main_page_parser(document,data_source_url)
    hash_array = []
    current_page_releases = document.css("div.news-release-row")
    current_page_releases.each do |release|
      link = "#{MAIN_URL}" +  release.css("a")[0]['href']
      next if @already_fetched_links.include? link
      title = release.css("a").text.split("Read More").first.squish
      release_no = release.css("span.news-release-date").text.split(" ").last
      teaser =release.css("span.news-release-summary").text.gsub("Read More","").squish
      date = Date.parse(release.css("span.news-release-date").text.split("-").first).to_date
      article,contact_info = fetch_article_contact_info(link)

      data_hash = {}    
      data_hash = {
        title: title,
        teaser: teaser,
        article: article,
        link: link,
        date: date,
        release_no: release_no,
        contact_info: contact_info,
        data_source_url: data_source_url
      }
      hash_array << data_hash   
    end
    UsItc.insert_all(hash_array) if !hash_array.empty?
    return @flag = true if hash_array.count < current_page_releases.count
  end

  def fetch_article_contact_info(link)
    document = connect_to(link)
    contact_info = document.css("strong")[3].to_s
    document.css("img").remove
    document.css("figure").remove
    document.css("iframe").remove
    document.css("script").remove
    document.css("strong").remove
    article = document.css("main").to_s
    [article,contact_info]
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
