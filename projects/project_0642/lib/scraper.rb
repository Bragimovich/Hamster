# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize(*_)
    safe_connection { super }
    @proxy_filter  = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304, 302].include?(response.status) }
  end

  def download_csv (link)
    Hamster.logger.info("Start download")
    clean_store
    start_browser

    @browser.go_to("https://www.iacourtcommissions.org/ords/f?p=106:1:111288738549229:::::")
    public_btn = waiting_until_element_found("//button[contains(text(), 'Public')]")
    public_btn.focus.click
    search_law_option = waiting_until_element_found("//a[contains(text(), 'Search the Lawyer Database')]")
    search_law_link = search_law_option.attribute('href')
    Hamster.logger.info("Go  to search law ink ")

    @browser.go_to("https://www.iacourtcommissions.org/ords/#{search_law_link}")

    input_field = waiting_until_element_found("//label[contains(text(), 'Last Name:')]/following::div//input[contains(@id,'LASTNAME')][contains(@name,'LASTNAME')]")
    input_field.focus.type('%', :Enter)
    Hamster.logger.info("Typed $ in input")
    sleep 30

    button_download = waiting_until_element_found("//div[@class='t-Report-links']/a[contains(text(), 'Download')]")
    button_download.click

    start_time = Time.now

    while Dir.glob("#{storehouse}*").find{ |x| x.match? /.csv$/ }.nil?
      sleep(1)
      Hamster.logger.info("Downloading file for #{(Time.now - start_time).to_i} seconds")
      break if Time.now - start_time >= 900
     end
   
    Hamster.logger.info("File saved successfully")

    close_browser
  end

  def clean_store
    FileUtils.rm(Dir.glob("#{storehouse}*"), :force => true )
  end

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    while (element.nil?)
      element = element_search(search)
      sleep 2
      break unless element.nil?
      counter +=1
      break if (counter > 20)
    end
    element
  end

  def element_search(search)
    @browser.at_xpath(search)
  end

  def start_browser
    @hammer  = Dasher.new(using: :hammer, headless: true, proxy_filter: @proxy_filter)
    @browser = @hammer.connect
  end

  def close_browser
    Hamster.logger.debug "closing browser"
    @browser.quit rescue nil
    @hammer.close rescue nil
  end

  def safe_connection(retries=10) 
    begin
      yield if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        Hamster.logger.error(e.class)
        sleep 100
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end

      retry
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end
  