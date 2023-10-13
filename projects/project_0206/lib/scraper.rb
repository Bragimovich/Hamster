# frozen_string_literal: true

require_relative 'parser'

class EnergyScraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  DEPARTMENTS =
    {EnergyAI => 'https://www.energy.gov/ai/listings/ai-news',
     EnergyCESER => 'https://www.energy.gov/ceser/listings/news-highlights',
     EnergyNE => 'https://www.energy.gov/ne/listings/ne-press-releases',
     EnergyLM => 'https://www.energy.gov/lm/listings/lm-news-archive',
     EnergyFECM =>  'https://www.energy.gov/fecm/listings/fecm-press-releases-and-techlines',
     EnergyEM =>  'https://www.energy.gov/em/listings/em-news-archive',
     EnergyEERE =>  'https://www.energy.gov/eere/listings/eere-news-releases',
     EnergyIndianenergy =>  'https://www.energy.gov/indianenergy/listings/office-indian-energy-news-blog',
     EnergyOE =>  'https://www.energy.gov/oe/listings/oe-news-archive'
    }

  def download
    begin
      DEPARTMENTS.each_pair do |model, url|
      @start_time = Time.now
      @parser = EnergyParser.new(model)
      run =  model.all.to_a.empty? ? nil : 1
      # peon.throw_trash if run
      scrapping_new_data(run, model, url)
      msg = "#206 US Dept of Energy offices news - The script loaded new data successfully at #{Time.now}"
      Hamster.report to: 'URYM6LD9V', message: msg
      end
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      msg = "#206 US Dept of Energy offices news - The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
      Hamster.report to: 'URYM6LD9V', message: msg
    end
  end

  private
  def scrapping_new_data(run, model, link)
    begin
      page_num = 1
      proceed_date = (Date.today - 14)
      begin
        puts "Page #{page_num} new data processing".green

        url = "#{link}?page=#{page_num-1}"
        page = get_news_page(url)
        sleep(rand(1..1.5))
        news_links = @parser.get_news_links(page)

        existing_news_date = nil
        if news_links != 'all pages proceed'
          news_links.each do |link|
            existing_news = model.find_by(link: link)
            next if existing_news.nil? || existing_news[:article]
            existing_news_date = existing_news[:date] if existing_news
            puts link.green
            news_page = get_news_page(link)
            next if news_page == 'overload'
            save_pages(model, news_page, link)
            sleep(rand(0.5..1.5))
          end
        end

        unless run
          statement = (news_links != 'all pages proceed')
        else
          statement = (existing_news_date && existing_news_date >= proceed_date)
        end

        page_num += 1
      end while statement
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #206 US Dept of Energy offices news failed - #{e} | #{e.backtrace}"
    end
  end

  def get_news_page(link)
    begin
      if Time.now > (@start_time + 20000)
        Hamster.report to: 'URYM6LD9V', message: "#206 US Dept of Energy offices news - unable to receive data from the site."
        puts "Process aborted".green
        return 'overload'
      end
      request = Hamster.connect_to(
        url: link,
        proxy_filter: @proxy_filter,
        ssl_verify: false,
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

  def save_pages(model, html, link)
    subfolder = 'releases'
    peon.put content: create_content(model, html, link), file: "#{Time.now.to_i.to_s}", subfolder: subfolder
  end

  def create_content(model, body, url)
    "#{model}|||#{url}|||#{body}"
  end
end


