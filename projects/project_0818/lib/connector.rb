require 'cgi'
class MdInmateConnector < Hamster::Scraper
  COOKIE_ATTRIBUTES = %w[path domain expires secure httponly samesite]

  def initialize(starting_url)
    super

    @starting_url      = starting_url
    @proxy_changed_at  = Time.now
    raise 'Starting URL must be provided' unless @starting_url
  end

  # Try connect
  def do_connect(url, method: :get, data: nil, save_cookies: true, use_cookies: true)
    update_proxy_and_cookie if @proxy.nil?
    headers               = default_header
    response              = nil
    retry_proxy_count     = 0

    sleep(rand(5..7))

    if method == :post && data
      req_body = params_encoded(data)
      headers = headers.merge(content_type: 'application/x-www-form-urlencoded')
    end

    begin
      raise SwapProxyRequiredError if @proxy_changed_at < Time.now - 50.minutes

      cookies =
        if use_cookies && @cookies
          cookie_val = @cookies.map{ |key, val| "#{key}=#{val}" }.join('; ')
          { cookie: cookie_val }
        end
      response = connect_to(url, cookies: cookies, headers: headers, method: method, proxy: @proxy, ssl_verify: false, req_body: req_body)      

      if response&.status == 302
        location = response.headers['location']
        location_url = Scraper::BASE_URL + location
        response = connect_to(location_url, cookies: cookies, headers: headers, proxy: @proxy, ssl_verify: false)
      elsif response&.success?

      else
        logger.info "The request not successful---#{response&.status}"
        raise SwapProxyRequiredError
      end
    rescue SwapProxyRequiredError => e
      raise e if retry_proxy_count > 10

      logger.info "Raised(#{retry_proxy_count}) and updated proxy to #{@proxy}"
      update_proxy_and_cookie
      
      retry_proxy_count += 1
      retry
    rescue StandardError => e
      logger.info 'Raised standard error from do_connect'
      logger.info e.full_message

      raise e
    end

    save_cookies_from_response(response) if response
    response
  end

  private

  class SwapProxyRequiredError < StandardError; end

  def default_header
    header = {}
    header['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36'
    header['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
    header['Accept-Language'] = 'en-US,en;q=0.9'
    header['Referer'] = 'https://www.ms.gov'
    header['Connection'] = 'keep-alive'
    header['Upgrade-Insecure-Requests'] = '1'
    header
  end

  def params_encoded(params)
    params.map{|key, val| "#{CGI.escape(key)}=#{CGI.escape(val)}"}.join('&')
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

      logger.info("update_proxy_and_cookie #{proxy_url}")
      save_cookies_from_response(response)
      @proxy = proxy_url
      @proxy_changed_at = Time.now
      break
    rescue StandardError => e
      logger.info e.full_message

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

      next if COOKIE_ATTRIBUTES.include?(cookie_key_val[0].downcase)
      
      @cookies[cookie_key_val[0]] = cookie_key_val[1]
    end
  end
end
