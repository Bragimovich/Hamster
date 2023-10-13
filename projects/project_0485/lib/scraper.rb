# frozen_string_literal: true

require_relative '../models/ks_court_kscourts_runs'
require_relative '../models/ks_court_kscourts_org'

class Scraper < Hamster::Scraper
  MAIN_URL = "https://directory-kard.kscourts.org/"

  def initialize(*_)
    safe_connection { super }
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @run_id = nil
  end

  def scrape_new_data(letter)
    response = connect_to(MAIN_URL, proxy_filter: @filter, ssl_verify: false)
    page = response&.body
    token = Nokogiri::HTML(page).at('form input')['value']  
    cookie = response&.headers['set-cookie']

    url = MAIN_URL + 'Search'
    headers = { Content_Type: 'application/x-www-form-urlencoded', Cookie: cookie }
    form_data = "__RequestVerificationToken=#{token}&RegNum=&LastName=#{letter}&FirstName=&Authenticated=False"

    index = connect_to(url,
                       proxy_filter: @filter,
                       ssl_verify: false,
                       method: :post,
                       req_body: form_data,
                       headers: headers
            )&.body 
  end

  def get_inner_record(link)
    connect_to(url: "https://directory-kard.kscourts.org#{link}")&.body
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    safe_connection {
      10.times do
        response = super(*arguments, &block)
        reporting_request(response)
        break if response&.status && [200, 304].include?(response.status)
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
