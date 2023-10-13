require_relative '../lib/parser'

class Scraper <  Hamster::Scraper

  def initialize
    safe_connection { super }
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      if [301, 302].include? response&.status
        url = response.headers["location"]
        url = "https://markets.ft.com" + url
        response =  Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end

  def safe_connection(retries=10)
    begin
      yield if block_given?
    rescue *CONNECTION_ERROR_CLASSES => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error(e)
        sleep 100
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *CONNECTION_ERROR_CLASSES => e
        retry
      end

      retry
    end
  end

end
