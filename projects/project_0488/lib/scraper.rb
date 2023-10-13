# frozen_string_literal: true
require_relative 'parser'
require_relative '../models/il_will_runs'

class ILWillScraper < Hamster::Scraper
  def initialize(run = 1)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @parser = ILWillParser.new(run)
    @run = run
  end

  def download
    begin
      report_types = ['Public', 'Press']
      report_types.each do |type|
      @start_time = Time.now
      date_to = Date.today
      date_to_year = date_to.year
      date_to_month = date_to.month
      date_to_day = date_to.day
      date_from_year = date_to_year - 2

      url = "http://66.158.36.230/NewWorld.InmateInquiry/#{type}?BookingFromDate=1%2F1%2F#{date_from_year}%2000%3A00%3A00&BookingToDate=#{date_to_month}%2F#{date_to_day}%2F#{date_to_year}%2023%3A59%3A59&Page="
      scrapping_by_pages(url, type)
      end
      msg = "#488 Crime Data for Perps held on Bail - Will, IL - The script loaded new data successfully at #{Time.now}"
      Hamster.report to: 'URYM6LD9V', message: msg
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      msg = "#488 Crime Data for Perps held on Bail - Will, IL - The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
      Hamster.report to: 'URYM6LD9V', message: msg
    end
  end

  private
  def scrapping_by_pages(link, type)
    begin
      page_num = 1
      get_arestees_info if (page_num == 1) && type != 'Public'
      begin
        link = "http://66.158.36.230/NewWorld.InmateInquiry/#{type}?Name=&SubjectNumber=&BookingNumber=&BookingFromDate=&BookingToDate=&InCustody=&Page=" if page_num > 1
        url = link + page_num.to_s
        puts "Data type - #{type}; Page #{page_num} data processing".green
        puts url.green

        index_page = get_news_page(url)
        save_pages(index_page, url, "run_#{@run}_index_#{type.downcase}")
        bookers_links =  @parser.get_bookers_links(index_page, type)
        sleep(rand(1..1.5))

        if bookers_links != 'all pages proceed' && type != 'Public'
          bookers_links.each do |link_d|
            if type == 'Public'
            link, _name, status = link_d
            else
              link = link_d.first
              name = link_d[1]
              status = get_status(link, name)
            end
            puts link.green if link
            booker_page = get_news_page(link)
            next if booker_page == 'overload'
            save_pages(booker_page, link,"run_#{@run}_bookers_#{type.downcase}", status)
            sleep(rand(0.5..1.5))
            end
          end

        statement = (bookers_links != 'all pages proceed')

        page_num += 1
      end while statement
    rescue => e
      puts "#{e} | #{e.backtrace}"
    end
  end

  def get_news_page(link)
    begin
      if Time.now > (@start_time + 100000)
        Hamster.report to: 'URYM6LD9V', message: " #488 Crime Data for Perps held on Bail - Will, IL - unable to receive data from the site."
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
  def get_arestees_info
    @arrestees_info = File.readlines("#{storehouse}store/public_records_list/public_records_run_#{@run}")
                     .map{|i| i.split('|||')}
  end
  def get_status(link, name)
    arrestee_number = (/[0-9]{1,}$/.match(link).to_s)
    probable_status = @arrestees_info.select{|i| i.first == arrestee_number}.flatten
    status = ((!probable_status.empty? && (probable_status[1] == name)) ?  probable_status.last : '')
    @arrestees_info.delete(probable_status) if !probable_status.empty? && (probable_status[1] == name)
    status
  end
  def save_pages(html, link,  subfolder, status = '')
    file_name = (
                if subfolder.include?('index')
                  Time.now.to_i.to_s
                else
                  /[0-9]{1,}$/.match(link).to_s
                end
                 )
    peon.put content: create_content(html, link, status), file: file_name, subfolder: subfolder
  end
  def create_content(body, url, status = '')
    "#{url}|||#{body}|||#{status}"
  end
end

