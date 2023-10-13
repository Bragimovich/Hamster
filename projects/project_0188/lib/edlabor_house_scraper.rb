require_relative '../models/edlabor_house'

class EdlaborHouseScraper < Hamster::Scraper
  TASK_NAME = '#188 Federal Registry: Education & Labor Committee'.freeze
  SLACK_ID  = 'Eldar Eminov'.freeze
  HOST      = 'edlabor.house.gov'.freeze

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
  end

  def start
    scrap   = scrapping_new_data
    message = "#{TASK_NAME} --download:\nCompleted successfully scraping at #{Time.now}.\n"
    message += scrap.zero? || scrap.nil? ? "The #{HOST} website has no new data." : "Total scraped on site #{HOST}: #{scrap}"
    report_success(message)
  rescue StandardError => e
    puts "#{e} | #{e.backtrace}"
    Hamster.report(to: SLACK_ID, message: e, use: :both)
  end

  private

  def scrapping_new_data
    count_scrap = 0
    links_db    = EdlaborHouse.all.select(:link).map(&:link)
    page_num    = 1
    concurrence = nil
    links       = true
    while !concurrence && links
      puts "Page #{page_num} new data processing".green
      url       = "https://#{HOST}/media/press-releases?PageNum_rs=#{page_num}"
      page      = get_body_of_page(url)
      links     = get_news_links(page)
      next unless links

      new_links = []
      links.each { |link| links_db.include?(link) ? concurrence = true : new_links << link }
      unless new_links.empty?
        new_links.each do |link|
          sleep(rand(0.3..1))
          article_page = get_body_of_page(link)
          md5     = MD5Hash.new(columns: %i[link])
          md5.generate({link: link})
          file_name = md5.hash
          peon.put(content: article_page, file: file_name)
          count_scrap += 1
        end
      end
      page_num += 1
    end
    count_scrap
  end

  def get_body_of_page(link)
    filter = @proxy_filter
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: filter, ssl_verify: false)
  end

  def connect_to(*arguments)
    response = nil
    10.times do
      response = super(*arguments)
      break if response&.status && [200, 304].include?(response.status)
    end
    response&.body
  end

  def get_news_links(page)
    html = Nokogiri::HTML(page)
    return false if html.css('#newscontent #press').empty?

    html.css('#newscontent #press h2.title a').map { |i| "https://#{HOST}#{i['href']}" }
  end

  def report_success(message)
    puts message.green
    time = Time.now
    if time.wday >= 1 && time.wday <= 5 && time.hour > 1 && time.hour < 10
      Hamster.report(to: SLACK_ID, message: message, use: :both)
    end
  end
end
