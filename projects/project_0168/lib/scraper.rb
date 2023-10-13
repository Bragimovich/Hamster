require_relative '../models/us_postal_service'
require_relative 'parser'

class USPostalServiceScraper < Hamster::Scraper
  LOGFILE = "#{ENV['HOME']}/cron_tasks/logs/project_0168_log"
  #LOGFILE = "#{ENV['HOME']}/HarvestStorehouse/project_0168/store/project_0168_log.txt"
  def initialize
    super
    @parser = USPostalServiceParser.new
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def download_data
    begin
      @start_time = Time.now
      run =  USPostalService.all.to_a.empty? ? nil : 1
      peon.throw_trash if run
      scrapping_new_data(run)
      msg = "The script loaded new data successfully at #{Time.now}"
      save_log(msg)
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      msg = "The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
      save_log(msg)
    end
  end

  def store_data
    @parser.parse_data
  end

  private
  def scrapping_new_data(run)
      if run
        years = [Date.today.year]
      else
        years = (2009..Date.today.year).to_a
      end

      proceed_date = (Date.today - 14)
      years.each do |year|
        begin
          puts "Year #{year} new data processing".green

          url = "https://about.usps.com/newsroom/national-releases/#{year}/data.json"
          page = get_news_page(url)
          sleep(rand(1..3))
          news_links = @parser.get_news_links(page)

          existing_news_date = nil
            news_links.each do |link|
              existing_news = USPostalService.find_by(link: link)
              next if existing_news.nil?
              existing_news_date = existing_news[:date] if existing_news
              break if run && existing_news_date && (existing_news_date < proceed_date)
              puts link.green
              link = link.encode( 'Windows-1251', :invalid => :replace, :undef => :replace)
              news_page = get_news_page(link)
              save_pages(news_page, link)
              sleep(rand(0.5..1.5))
            end

          rescue StandardError => e
            puts "#{e} | #{e.backtrace}"
            Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #168 U.S. Postal Office failed - #{e} | #{e.backtrace}"
          end
        end
  end

  def get_news_page(link)
    begin
      if Time.now > (@start_time + 3600)
        Hamster.report to: 'URYM6LD9V', message: "#168 U.S. Postal Office - unable to receive data from the site."
        puts "Process aborted".green
        exit
      end
      request = Hamster.connect_to(
        url: link,
        proxy_filter: @proxy_filter,
        method: :get
      )
      raise if request&.headers.nil?

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      retry
    end
    request.body
  end

  def save_pages(html, link)
    subfolder = 'releases'
    peon.put content: create_content(html, link), file: "#{Time.now.to_i.to_s}", subfolder: subfolder
  end

  def create_content(body, url)
    "#{url}|||#{body}"
  end

  def save_log(msg)
    File.open(LOGFILE, 'a') do |name|
      name.puts msg
    end
  end
end

