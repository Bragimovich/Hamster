require 'cgi'

class TributeConnector < Hamster::Scraper
  COOKIE_ATTRIBUTES = %w[path domain expires secure httponly samesite]
  MAX_RETRY = 5

  def initialize(base_url)
    super

    @base_url = base_url
    @token_expire_at = Time.now
    @token_url = "#{@base_url}/archiveapi/token"
    @banned_proxies = []
    raise 'Starting URL must be provided' unless @base_url&.length&.positive?
  end

  # Try connect
  def do_connect(url, method: :get, data: nil, token: nil)
    update_proxy_and_token if @proxy.nil?
    update_proxy_and_token if @proxy && @token_expire_at <= Time.now

    sleep(rand(7..10))

    headers = {'Authorization' => "Bearer #{token || @token}"}
    if method == :post && data
      req_body = JSON.generate(data)
      headers = headers.merge(content_type: 'application/json')
    end

    retry_count = 0
    retry_update_token = 0
    response = nil
    
    begin
      cookies =
        if @cookies
          cookie_val = @cookies.map{ |key, val| "#{key}=#{val}" }.join('; ')
          { cookie: cookie_val }
        end
      response = connect_to(url, cookies: cookies, headers: headers, method: method, proxy: @proxy, ssl_verify: false, req_body: req_body)

      # raise UpdateTokenAndRetry if response&.status.to_i == 401
      raise SwapProxyRequiredError unless response&.success?
    rescue SwapProxyRequiredError => e
      logger.debug '---SwapProxyRequiredError'
      logger.debug "url: #{url}, status: #{response&.status}, body: #{response&.body}"
      raise e if retry_count > MAX_RETRY

      sleep retry_count
      update_proxy_and_token

      retry_count += 1
      retry
    rescue UpdateTokenAndRetry => e
      logger.debug '---UpdateTokenAndRetry'
      logger.debug "url: #{url}, status: #{response&.status}, body: #{response&.body}"
      raise e if retry_update_token > MAX_RETRY

      sleep 25
      update_token

      retry_update_token += 1
      retry
    rescue StandardError => e
      raise e
    end

    save_cookies_from_response(response)
    response
  end

  def update_proxy_and_token
    @proxy = nil
    PaidProxy.where(is_socks5: 1).to_a.shuffle.each do |proxy|
      proxy_url = proxy_url(proxy)

      next if @banned_proxies.include?(proxy_url)

      response = connect_to('https://www.tributearchive.com', method: :get, proxy: proxy_url, ssl_verify: false)
      save_cookies_from_response(response) if response&.success?

      response = connect_to(@token_url, method: :get, proxy: proxy_url, ssl_verify: false)
      logger.debug "Updating proxy and token - proxy: #{proxy_url}"

      unless response&.success?
        @banned_proxies << proxy_url

        next
      end

      save_cookies_from_response(response)

      body = JSON.parse(response.body)
      @token = body['access_token']
      @token_expire_at = Time.now + 50.minutes
      @proxy = proxy_url
      logger.debug "Found working proxy: #{proxy_url} and token"

      break
    rescue StandardError => e
      # logger.info e.full_message
      logger.info 'Next proxy, Raised when updating proxy and token'
      
      next
    end

    raise 'Could not find the working proxy' if @proxy.nil?
  end

  private

  class SwapProxyRequiredError < StandardError
    def initialize
      super('The request is not successful, required change proxy')
    end
  end

  class UpdateTokenAndRetry < StandardError; end

  # Get proxy URL for PaidProxy object
  def proxy_url(proxy)
    port = proxy.port
    scheme = proxy.is_socks5 ? 'socks' : 'https'
    "#{scheme}://#{proxy.login}:#{proxy.pwd}@#{proxy.ip}:#{port}"
  end

  def update_token
    response = connect_to(@token_url, method: :get, proxy: @proxy, ssl_verify: false)
    logger.info "Updating token with proxy: #{@proxy} -> #{response.body}"
    if response&.success? && response.body.include?('access_token')
      body = JSON.parse(response.body)
      @token = body['access_token']
      @token_expire_at = Time.now + 50.minutes
    else
      update_proxy_and_token
    end
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
