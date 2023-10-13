# frozen_string_literal: true

class Scraper < Hamster::Scraper
  ORIGIN = "https://nmonesource.com"

  def initialize(*_)
    safe_connection { super }
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def get_outer_page(**terms)
    page = "?page=#{terms[:page]}&" if terms[:page]
    url = "#{ORIGIN}/nmos/#{terms[:type]}/en/#{terms[:year]}/nav_date.do?#{page&.slice(1..)}iframe=true"
    headers = base_headers.merge("Referer": "#{ORIGIN}/nmos/nmsc/en/#{terms[:year]}/nav_date.do#{page&.slice(..-2)}")
    connect_to(url: url , proxy_filter: @proxy_filter, headers: headers)&.body
  end

  def get_inner_page(link)
    url = ORIGIN + link.sub(/#{ORIGIN}/, '') + "?iframe=true"
    sleep 3
    headers = base_headers.merge("Referer": "#{ORIGIN}#{link}")
    connect_to(url: url , proxy_filter: @proxy_filter, headers: headers)&.body
  end

  def download_pdf(url, tries: 100)
    response = safe_connection { Hamster.connect_to(url: url, proxy_filter: @proxy_filter) }
    reporting_request(response)
    raise if response.nil? || response.status != 200
    response.body
  rescue => e
    tries -= 1
    if tries < 1
      return nil
    else
      sleep(rand(10))
      Hamster.logger.info("PDF not downloaded....Retry....")
      retry
    end
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    safe_connection { 
      10.times do
        response = super(*arguments, &block)
        reporting_request(response)
        break if response&.status && [200].include?(response.status)
      end
    }
    response
  end

  def reporting_request(response)
    Hamster.logger.debug '=================================='
    Hamster.logger.info 'Response status: '.indent(1, "\t")
    status = response&.status
    Hamster.logger.info status.to_s
    Hamster.logger.debug '=================================='
  end  

  def base_headers
    {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Host": "nmonesource.com",
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36 Edg/109.0.1518.70",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "Windows",
      "Sec-Fetch-Dest": "iframe",
      "Sec-Fetch-Mode": "navigate",
      "Sec-Fetch-Site": "same-origin"
    }
  end

  def safe_connection(retries=10) 
    begin
      yield if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        Hamster.logger.error(e.class)
        Hamster.logger.error("Reconnect!")
        sleep 100
        Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Scraper: Reconnecting...")
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
