# frozen_string_literal: true

require 'cgi'
require_relative 'parser'
class MarylandConnector < Hamster::Scraper
  attr_reader :proxy

  COOKIE_ATTRIBUTES = %w[path domain expires secure httponly samesite].freeze
  MAX_RETRY = 1

  def initialize(starting_url, manager)
    super

    @manager      = manager
    @starting_url = starting_url

    raise 'Starting URL must be provided' unless @starting_url&.length&.positive?
  end

  # Try connect
  def do_connect(url, method: :get, data: nil, save_cookies: true, use_cookies: true)
    update_proxy_and_cookie if @proxy.nil?
    headers = md_headers.merge('Referer': @referer_url)

    sleep(rand(1.5..5.5))

    if method == :post && data
      req_body = params_encoded(data)
      if data.include?('lastName')
        headers  = headers.merge(
          content_type: 'application/x-www-form-urlencoded',
          'Content-Length': req_body.length.to_s,
          'Sec-Fetch-Site': 'same-origin',
          'Origin': 'https://casesearch.courts.state.md.us'
        )
      end
    end

    retry_count = 0
    response = nil

    begin
      cookies =
        if use_cookies && @cookies
          cookie_val = @cookies.map { |key, val| "#{key}=#{val}" }.join('; ')
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
      @referer_url = url
      puts "===========begin======#{@proxy}===#{url}===#{response&.status}==="
      p data, cookies
      raise "The request not successful---status code: #{response&.status}--#{@proxy}" unless response&.success?
    rescue StandardError => e
      retry_count += 1

      raise e if retry_count > MAX_RETRY

      update_proxy_and_cookie

      retry
    end

    save_cookies_from_response(response) if save_cookies

    response
  end

  private

  def md_headers
    # default headers
    {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Accept-Language': 'en-US,en;q=0.9',
      'Cache-Control': 'max-age=0',
      'Connection': 'keep-alive',
      'Host': 'casesearch.courts.state.md.us',
      'sec-ch-device-memory': '8',
      'sec-ch-ua': '"Chromium";v="110", "Not A(Brand";v="24", "Google Chrome";v="110"',
      'sec-ch-ua-arch': "x86",
      'sec-ch-ua-full-version-list': '"Chromium";v="110.0.5481.177", "Not A(Brand";v="24.0.0.0", "Google Chrome";v="110.0.5481.177"',
      'sec-ch-ua-platform': '"Linux"',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36'
    }
  end

  def params_encoded(params)
    params.map { |key, val| "#{CGI.escape(key)}=#{CGI.escape(val)}" }.join('&')
  end

  # Get proxy URL for PaidProxy object
  def proxy_url(proxy)
    port = proxy.port
    scheme = proxy.is_socks5 ? 'socks' : 'https'
    "#{scheme}://#{proxy.login}:#{proxy.pwd}@#{proxy.ip}:#{port}"
  end

  def update_proxy_and_cookie
    @proxy = nil
    
    @manager.paid_proxies.to_a.shuffle.each do |proxy|
      proxy_url = proxy_url(proxy)

      next unless @manager.valid_proxy?(proxy_url)

      response = connect_to(@starting_url, method: :get, ssl_verify: false, headers: md_headers)
      puts "================= update_proxy_and_cookie =========#{proxy_url}========#{response&.status}".yellow 
      if response&.success?
        save_cookies_from_response(response)
        @proxy = proxy_url
        send_disclaimer(response.body)
        @referer_url = @starting_url

        @manager.using_on(proxy_url)

        break
      else
        @manager.ban_proxy(proxy_url)

        next
      end      
    rescue StandardError
      @manager.ban_proxy(proxy_url)

      next
    end

    raise 'Could not find the working proxy' if @proxy.nil?
  end

  def send_disclaimer(response_body)
    cookie_val = @cookies.map { |key, val| "#{key}=#{val}" }.join('; ')
    cookies = { cookie: cookie_val }
    disclaimer = Parser.new.disclaimer(response_body)
    response = connect_to(
      @starting_url,
      cookies: cookies,
      method: :post,
      proxy: @proxy,
      ssl_verify: false,
      headers: md_headers.merge(content_type: 'application/x-www-form-urlencoded'),
      req_body: params_encoded({ 'disclaimer' => disclaimer  })
    )
    puts "================= sent disclaimer =======#{@proxy}====#{disclaimer}===#{cookies}======".greenish
    puts response&.body
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
