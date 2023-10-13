require 'cgi'
require_relative 'parser'
class CaOcscCaseConnector < Hamster::Scraper
  COOKIE_ATTRIBUTES = %w[path domain expires secure httponly samesite]

  def initialize(starting_url)
    super

    @captcha_client  = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
    @starting_url    = starting_url
    @required_captcha_count = 0
    raise 'Starting URL must be provided' unless @starting_url&.length&.positive?
  end

  # Try connect
  def do_connect(url, method: :get, data: nil, save_cookies: true, use_cookies: true)
    update_proxy_and_cookie if @proxy.nil?
    headers               = default_header
    response              = nil
    retry_proxy_count     = 0
    retry_captcha_count   = 0
    retry_connect_count   = 0
    required_captcha      = false
    required_change_proxy = false
    sleep(rand(2.5..5.5))
    if method == :post && data
      req_body = params_encoded(data)
      @cookies['searchTab'] = 1 if data['startFilingDate']
      headers = headers.merge(content_type: 'application/x-www-form-urlencoded')
    end

    begin
      cookies =
        if use_cookies && @cookies
          cookie_val = @cookies.map{ |key, val| "#{key}=#{val}" }.join('; ')
          { cookie: cookie_val }
        end
      response = connect_to(url, cookies: cookies, headers: headers, method: method, proxy: @proxy, ssl_verify: false, req_body: req_body)      

      # When received a captcha page
      if response && Parser.new.required_captcha?(response.body)
        required_captcha = true

        raise 'Received a response that requires me to solve the captcha.'
      end

      # Redirecting to show case page when sent search case request
      if url == Scraper::SEARCH_CASE_PAGE && response.status == 302
        show_case_url = "#{Scraper::HOST}#{response.headers['location']}"
        response = connect_to(show_case_url, cookies: cookies, headers: headers, method: :get, proxy: @proxy, ssl_verify: false)
      end

      unless response&.success?
        required_change_proxy = true
        logger.info 'The request not successful'
        raise 'The request not successful'
      end
    rescue StandardError => e
      if required_captcha
        raise e if retry_captcha_count > 1
        @required_captcha_count += 1 if url.downcase.include?('searchcase.do')
        logger.info "Sending(#{@required_captcha_count}) captcha solve request pageurl is #{url} and param is #{data}"
        if @required_captcha_count > 10
          @required_captcha_count = 0
          logger.info "Sent solve recaptcha request 10 times, sleeping 10 mins"
          # sleep 60 * 10 # Sleeping to avoid the captcha time range.
        end
        data = data.merge('g-recaptcha-response' => captcha_token(url))
        req_body = params_encoded(data)
        required_captcha = false
        retry_captcha_count += 1
      elsif required_change_proxy
        raise e if retry_proxy_count > 3

        @required_captcha_count = 0
        sleep 30
        update_proxy_and_cookie
        logger.info "Raised(#{retry_proxy_count}) and updated proxy to #{@proxy}"
        retry_captcha_count = 0
        required_change_proxy = false
        retry_proxy_count += 1
      else
        logger.info e.full_message

        # When Can't connect to MySQL server on 'db02.blockshopper.com'
        raise e if retry_connect_count > 30

        retry_connect_count += 1
        logger_message = "Lost connection(#{retry_connect_count}), sleeping #{retry_connect_count * retry_connect_count * 10} seconds"
        logger.info logger_message

        sleep retry_connect_count * retry_connect_count * 10
        try_reconnect
      end
      
      retry
    end

    save_cookies_from_response(response) if save_cookies
    response
  end

  private

  def default_header
    header = {}
    header['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36'
    header['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
    header['Accept-Language'] = 'en-US,en;q=0.9'
    header['Referer'] = 'https://civilwebshopping.occourts.org/Search.do'
    header['Connection'] = 'keep-alive'
    header['Cookie'] = "searchTab=1; JSESSIONID=#{@cookies['JSESSIONID']}"
    header['Upgrade-Insecure-Requests'] = '1'
    header
  end

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
      accept_terms!(response)
      @proxy = proxy_url

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
    @cookies['ARRAffinitySameSite'] = @cookies['ARRAffinity'] unless @cookies['ARRAffinitySameSite']
  end

  def accept_terms!(response)
    return unless Parser.new.terms_page?(response.body)

    retry_count = 0
    headers     = { content_type: 'application/x-www-form-urlencoded' }
    req_body    = params_encoded({'action' => 'Accept Terms'})
    terms_page  = 'https://civilwebshopping.occourts.org/Search.do;jsessionid=' + @cookies['JSESSIONID']
    loop do
      break if retry_count > 1

      retry_count += 1
      cookie_val = @cookies.map{|key, val| "#{key}=#{val}"}.join('; ')
      cookies = { cookie: cookie_val }
      logger.info('Sending accept terms post request')      
      response = connect_to(terms_page, cookies:cookies, headers: headers, method: :post, proxy: @proxy, ssl_verify: false, req_body: req_body)

      break unless Parser.new.terms_page?(response.body)
    end
  end

  def captcha_token(pageurl)
    retry_count     = 0
    max_retry_count = 5

    raise '2captcha balance is unavailable' if @captcha_client.balance < 1

    options = {googlekey: '6LchwjgUAAAAAFHuvfk7MS5ONQtVv39PvrNE6wxg', pageurl: pageurl}
    begin
      decoded_captcha = @captcha_client.decode_recaptcha_v2!(options)
      decoded_captcha.text
    rescue StandardError, Hamster::CaptchaAdapter::CaptchaUnsolvable, Hamster::CaptchaAdapter::Timeout, Hamster::CaptchaAdapter::Error
      return if retry_count > max_retry_count
      sleep(10)

      retry_count += 1 
      retry
    end
  end
end
