require 'cgi'

class HsbaConnector < Hamster::Scraper
  COOKIE_ATTRIBUTES = %w[path domain expires secure httponly samesite]
  MAX_RETRY = 5
  MAX_RETRY_CONNECTING = 30

  def initialize(starting_url)
    super

    @starting_url = starting_url
    raise 'Starting URL must be provided' unless @starting_url&.length&.positive?
  end

  # Try connect
  def do_connect(url, method: :get, data: nil, save_cookies: true, use_cookies: true)
    update_proxy_and_cookie if @proxy.nil?

    sleep(rand(1.5..5.5))
    if method == :post && data
      req_body = params_encoded(data)
      headers = { content_type: 'application/x-www-form-urlencoded' }
    end

    retry_count = 0
    response = nil
    retry_connect_count = 0
    required_change_proxy = false
    begin
      cookies =
        if use_cookies && @cookies
          cookie_val =
            @cookies.map do |key, val|
              "#{key}=#{val}"
            end
            .join('; ')

          { cookie: cookie_val }
        end

      response =
        connect_to(
          url,
          cookies:    cookies,
          headers:    headers,
          method:     method,
          proxy:      @proxy,
          ssl_verify: false,
          req_body:   req_body
        )
      unless response&.success?
        required_change_proxy = true
        logger.info 'The request not successful'
        raise 'The request not successful'
      end
    rescue StandardError => e
      if required_change_proxy
        raise e if retry_count > MAX_RETRY

        logger.info 'Raised and updated proxy and sleeping'
        retry_count += 1

        required_change_proxy = false
        sleep retry_count * 10

        update_proxy_and_cookie
      else
        # When Can't connect to MySQL server on 'db02.blockshopper.com'
        raise e if retry_connect_count > MAX_RETRY_CONNECTING

        retry_connect_count += 1
        sleep_times = retry_connect_count * retry_connect_count * 10
        logger_message = "project_0532: Lost connection(#{retry_connect_count}), sleeping #{sleep_times} seconds"
        logger.info logger_message

        sleep sleep_times
        try_reconnect
      end

      retry
    end

    save_cookies_from_response(response) if save_cookies
    response
  end

  private

  def try_reconnect
    sleep_times = [2, 4, 8]

    begin
      PaidProxy.connection.reconnect!
    rescue StandardError => e
      sleep_time = sleep_times.shift
      if sleep_time
        sleep sleep_time

        retry
      end
    end
  end

  def params_encoded(params)
    params
      .map do |key, val|
        "#{CGI.escape(key)}=#{CGI.escape(val)}"
      end
      .join('&')
  end

  # Get proxy URL for PaidProxy object
  def proxy_url(proxy)
    port = proxy.port
    scheme = proxy.is_socks5 ? 'socks' : 'https'
    "#{scheme}://#{proxy.login}:#{proxy.pwd}@#{proxy.ip}:#{port}"
  end

  def update_proxy_and_cookie
    @proxy = nil

    PaidProxy.where(is_socks5: 1).to_a.shuffle.each do |proxy|
      proxy_url = proxy_url(proxy)
      response = connect_to(@starting_url, method: :get, proxy: proxy_url, ssl_verify: false)
      next unless response&.success?

      save_cookies_from_response(response)
      @proxy = proxy_url
      break
    rescue StandardError
      next
    end

    raise 'Could not find the working proxy' if @proxy.nil?
  end

  # Extract and save cookies from response
  def save_cookies_from_response(response)
    return if response.headers['set-cookie'].nil?

    @cookies ||= {}
    cookies_array = response.headers['set-cookie'].scan(/([^=,;\s]+=[^=,;]+)[;,]?/).flatten
    cookies_array.each do |cookie|
      cookie_key_val = cookie.split('=')
      unless COOKIE_ATTRIBUTES.include?(cookie_key_val[0].downcase)
        @cookies[cookie_key_val[0]] = cookie_key_val[1]
      end
    end
  end
end
