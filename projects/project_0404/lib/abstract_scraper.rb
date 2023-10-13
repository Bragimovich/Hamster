class AbstractScraper < Hamster::Scraper
  attr_reader :raw_content, :content_raw_html, :content_html, :cookie

  def initialize(option=nil)
    safe_connection { super }

    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }

    @accept = {
      "html" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "json" => "application/json, text/javascript, */*; q=0.01",
      "pdf" => "application/pdf"
    }
    @content_type = {
      "html" => "text/html",
      "json" => "application/json",
      "pdf"  => "application/pdf"
    }

    @cookie = {} 
  end

  def header(accept)
    @headers = {
      "Accept" => @accept[accept],
      "Accept-Encoding" => "gzip, deflate, br",
      "Content-Type" => @content_type[accept],
      "Connection" => "keep-alive"
    }

    @headers.merge!({ "X-Requested-With" => "XMLHttpRequest" }) if accept == "json"
  end

  def cookies
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def do_connect(*arguments, &block)
    accept = arguments.first[:accept] || 'html'
    header(accept)
    arguments.first.merge!({proxy_filter: @proxy_filter})
    arguments.first.merge!({cookies: {"cookie" => cookies}, headers: @headers} ) unless @cookie.empty?

    @raw_content      = connect_to(*arguments, &block)
    @content_raw_html = @raw_content.body
    @content_html     = Nokogiri::HTML5(@content_raw_html)
    @raw_set_cookie   = @raw_content.headers["set-cookie"]
    set_cookie @raw_set_cookie
    @raw_content
  end

  def set_cookie(raw_cookie)
    return if raw_cookie.nil?
    raw = raw_cookie.split(";").map do |item|
      if item.include?("Expires=")
        item.split("=")
        ""
      else
        item.split(",")
      end
    end.flatten

    raw.each do |item|
      if !item.include?("Path") && !item.include?("HttpOnly") && !item.include?("Secure") && !item.include?("secure") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    safe_connection { 
      10.times do
        response = super(*arguments, &block)
        reporting_request(response)
        break if response&.status && [200, 304, 302].include?(response.status)
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
        Hamster.logger.error("Scraper: Reconnecting...")
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
