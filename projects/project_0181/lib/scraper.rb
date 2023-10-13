require_relative '../models/idfc'
require_relative 'parser'

class IDFCScraper < Hamster::Scraper
  LOGFILE = "#{ENV['HOME']}/cron_tasks/logs/project_0181_log"
  #LOGFILE = "#{ENV['HOME']}/HarvestStorehouse/project_0181/store/project_0181_log.txt"
  def initialize
    super
    @parser = IDFCParser.new
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def download_data
    begin
      @start_time = Time.now
      run =  IDFC.all.to_a.empty? ? nil : 1
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
    begin
        page_num = 1
        proceed_date = (Date.today - 14)
        begin
          puts "Page #{page_num} new data processing".green

          url = "https://www.dfc.gov/media/newsroom?page=#{page_num-1}"
          page = get_news_page(url)
          sleep(rand(1..3))
          news_links = @parser.get_news_links(page)

          existing_news_date = nil
          if news_links != 'all pages proceed'
            news_links.each do |link|
              existing_news = IDFC.find_by(link: link)
              next if existing_news.nil?
              existing_news_date = existing_news[:date] if existing_news
              puts link.green
              news_page = get_news_page(link)
              save_pages(news_page, link)
              sleep(rand(0.5..1.5))
            end
          end

          if !run
            statement = (news_links != 'all pages proceed')
          else
            statement = (existing_news_date && existing_news_date >= proceed_date)
          end

          page_num += 1
        end while statement
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #181 International Development Finance Corporation failed - #{e} | #{e.backtrace}"
    end
  end

  def get_news_page(link)
    begin
      if Time.now > (@start_time + 3600)
        Hamster.report to: 'URYM6LD9V', message: "#181 International Development Finance Corporation - unable to receive data from the site."
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

