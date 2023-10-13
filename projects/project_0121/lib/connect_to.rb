# frozen_string_literal: true

require 'socksify'

class ConnectTo < Hamster::Scraper
  private

  def init_header
    @headers = {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "Accept-Encoding" => "gzip, deflate, br",
      "Accept-Language" => "en-US;q=0.8,en;q=0.3",
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Pragma" => "no-cache",
      "Cache-Control" => "no-cache",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
    }
  end

  def init_cookie
    @jar_cookie = HTTP::CookieJar.new
  end

  def init_proxies
    @proxies = PaidProxy.where(is_socks5: 1).to_a
    @proxy = @proxies.shuffle.first
  end

  public

  def initialize
    super
    init_header
    init_proxies
    init_cookie
  end

  def connect(**arguments, &block)
    headers      = arguments[:headers].dup || @headers
    req_body     = arguments[:req_body].dup || {}
    proxy        = arguments[:proxy].dup || @proxy
    cookies      = arguments[:cookies].dup || @jar_cookie.cookies
    url          = arguments[:url].dup
    proxy_addr = @proxy[:ip]
    proxy_port = @proxy[:port]
    proxy_user = @proxy[:login]
    proxy_passwd = @proxy[:pwd]

    TCPSocket.socks_username = proxy_user
    TCPSocket.socks_password = proxy_passwd
    uri = URI::parse(url)
    Net::HTTP.SOCKSProxy(proxy_addr, proxy_port).get(uri)
  end
end
