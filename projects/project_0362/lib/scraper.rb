require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

CONNECTION_ERROR_CLASSES =
  [
    ActiveRecord::ConnectionNotEstablished,
    Mysql2::Error::ConnectionError,
    ActiveRecord::StatementInvalid,
    ActiveRecord::LockWaitTimeout
  ]

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.ma-appellatecourts.org'
  end

  def page(url)
    safe_connection { connect_to(url, headers: { Host: @host }, proxy_filter: @proxy_filter, iteration: 9) }
  end

  def safe_connection(retries=10)
    begin
      yield if block_given?
    rescue *CONNECTION_ERROR_CLASSES => e
      begin
        retries -= 1
        raise 'Connection could not be established!' if retries.zero?
        logger.warn "Error: #{e.class}. Reconnect!"
        sleep 100 * (10-retries)
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *CONNECTION_ERROR_CLASSES => e
        retry
      end
      retry
    end
  end
end
