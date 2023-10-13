# frozen_string_literal: true

require 'socksify'

class Connect < Hamster::Scraper
  attr_writer :proxies
  def initialize
    super
    @cookie = {}
    @user_agent = FakeAgent.new
    @check_count = 0
    @proxies = proxies
  end

  def proxies
    PaidProxy.where(is_socks5: 1).to_a rescue nil
  end

  def cookies
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def connect(**arguments, &block)
    raise "No arguments given" if arguments.nil? || arguments.empty?
    retries = 0
    headers = {}
    headers = arguments[:headers].dup || headers
    req_body = arguments[:req_body].dup || {}
    cookie = arguments[:cookies].dup || cookies
    method = arguments[:method].dup || :get
    url = arguments[:url].dup
    headers.merge!(user_agent: @user_agent.any)
    headers.merge!(cookie: cookie) unless cookies.nil?
    pp url
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
        puts e.message
        puts e.full_message if @debug
        puts "Retry ##{retries}" if @debug
        retry
      else
        puts e.message
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

    set_cookie @raw_content['Set-Cookie'] 
    @raw_content
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
      if !item.include?("Path") && !item.include?("HttpOnly")  && !item.include?("Secure") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
  end
end
