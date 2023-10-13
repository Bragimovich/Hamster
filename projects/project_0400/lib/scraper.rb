require_relative '../lib/parser'
require_relative '../lib/message_send'

CONNECTION_ERROR_CLASSES =
  [
    ActiveRecord::ConnectionNotEstablished,
    Mysql2::Error::ConnectionError,
    ActiveRecord::StatementInvalid,
    ActiveRecord::LockWaitTimeout
  ]

class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
  end

  def get_items(url)
    hamster = nil
    hamster = safe_connection { connect_to(url, proxy_filter: @proxy_filter) }
    raise 'Hamster blank' if hamster.blank?
    raise 'Status != 200' if hamster.status != 200
    Parser.new.items_parse(hamster)
  rescue => e
    if hamster.blank?
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
    elsif hamster.status == 502
      logger.error "#{Time.now.strftime("%H:%M:%S")} Retry".red
      sleep(60)
      retry
    else
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
    end
  end

  def page(url)
    safe_connection { connect_to(url, proxy_filter: @proxy_filter, iteration: 9) }
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
