#frozen_string_literal: true

class Connect < Hamster::Scraper
  attr_writer :proxies
  def initialize(args)
    super
    @service = [:azcaptcha_com, :two_captcha_com, :captchas_io, :capsolver_com]
    @cookie = {}
    @user_agent = FakeAgent.new
    @check_count = 0
    @proxies = proxies
    @headers = ""

    @accept = {
      "html" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "json" => "application/json, text/javascript, */*; q=0.01",
      "pdf" => "application/pdf",
      "url_post" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
    }

    @content_type = {
      "html" => "text/html",
      "json" => "application/json",
      "pdf"  => "application/pdf",
      "url_post" => "application/x-www-form-urlencoded"
    }
  end

  def proxies
    PaidProxy.where(is_socks5: 1).to_a rescue nil
  end

  def cookies
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def delete_cookie
    @cookie = {}
  end

  def connect(**arguments, &block)
    raise "No arguments given" if arguments.nil? || arguments.empty?
    retries = 0
    headers = {}
    headers = arguments[:headers].dup || @headers
    req_body = arguments[:req_body].dup || {}
    cookie = arguments[:cookies].dup || cookies
    method = arguments[:method].dup || :get
    url = arguments[:url].dup
    headers.merge!(user_agent: @user_agent.any)
    headers.merge!(cookie: cookie) unless cookies.nil?
    begin
      @proxy = @proxies.sample
      proxy_addr = @proxy[:ip]
      proxy_port = @proxy[:port]
      proxy_user = @proxy[:login]
      proxy_passwd = @proxy[:pwd]

      uri = URI::parse(url)
      TCPSocket.socks_username = proxy_user
      TCPSocket.socks_password = proxy_passwd
      http_proxy = Net::HTTP.SOCKSProxy(proxy_addr, proxy_port).new(uri.host,uri.port)
      http_proxy.use_ssl = (uri.scheme == "https")

      @raw_content =
        if method == :get
          request = Net::HTTP::Get.new(uri, headers)
          http_proxy.request(request)
        elsif method == :post
          request = Net::HTTP::Post.new(uri.path, headers)
          request.body = req_body
          http_proxy.request(request)
        else
          nil
        end
    rescue Exception => e
      retries += 1
      sleep(retries**2)
      
      if retries <= 15
        @logger.debug(e.full_message)
        @logger.debug("Retry ##{retries}")
        @logger.error(e.full_message)
        @logger.info("Retry ##{retries}")
        retry
      else
        @raw_content = nil
      end
    else
      @raw_content 
    end

    if @check_count > 5000
      update_proxy = proxies
      @proxies = update_proxy unless update_proxy.nil?
      @check_count = 0 
    end
    @check_count += 1

    @content_html = Nokogiri::HTML(@raw_content.body)
    set_cookie @raw_content['Set-Cookie'] 
    @raw_content
  end

  def header(*args)
    arguments = args.first.dup
    accept = arguments[:accept]

    @headers = {
      "Accept" => @accept[accept],
      "Accept-Encoding" => "gzip, deflate, br",
      "Proxy-Authorization" => "Basic bm9paHRwa206aDRrYnUwa241cnVv",
      "Referer" => "https://circuitclerk.lakecountyil.gov/publicAccess/html/common/index.xhtml",
      "Origin" => "https://circuitclerk.lakecountyil.gov",
      "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
      "Content-Type" => @content_type[accept],
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Pragma" => "no-cache",
      "Cache-Control" => "no-cache"
    }
    @headers.merge!({ "X-Requested-With" => "XMLHttpRequest" }) if accept == "json"
  end

  def set_cookie raw_cookie
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
      if !item.include?("Path") && !item.include?("HttpOnly")  && !item.include?("Secure") && !item.include?("secure") && !item.include?("Domain") && !item.include?("path") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
  end
end
