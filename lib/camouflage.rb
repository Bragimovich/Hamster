# frozen_string_literal: true

require_relative 'storage'
require_relative 'paid_proxy'

class Camouflage
  
  SCHEME  = "((?<scheme>(https?|socks5?))://)?"
  ACCOUNT = "((?<username>[^:@]+):(?<password>[^:@]+)@)?"
  HOST    = "(?<host>\\d{1,3}[.]\\d{1,3}[.]\\d{1,3}[.]\\d{1,3})(:)?"
  PORT    = "(?<port>\\d{1,5})?"
  PROXY   = %r{#{SCHEME}#{ACCOUNT}#{HOST}#{PORT}}
  
  def initialize(proxies = nil, local_chrome: false)
    if [Array, String].include? proxies.class
      proxies = [proxies].flatten
      proxies.map! do |e|
        proxy_parts = e.match(PROXY)
        next if proxy_parts.nil?
        proxy_parts[:scheme].nil? ? "socks://#{e}" : e
      end
    else
      proxies = proxies ? proxies.to_a.shuffle : nil
    end
    
    @local_chrome = local_chrome
    @proxies      =
      if proxies.nil?
        paid_proxies = @local_chrome ? PaidProxy.where(is_http: 1).to_a : PaidProxy.where(is_socks5: 1).to_a
        Hamster.close_connection(PaidProxy)
        paid_proxies.shuffle
      else
        proxies
      end
  end
  
  def swap
    @proxies << @proxies.shift
    share
  end
  
  def share
    p = @proxies.first
    if p.is_a?(PaidProxy)
      if @local_chrome
        port = p.port_http
        scheme = 'http'
      else
        port = p.port
        scheme = p.is_socks5 ? 'socks' : 'https'
      end
      
      "#{scheme}://#{p.login}:#{p.pwd}@#{p.ip}:#{port}" # when it has been created I thought than 'socks' is enough to place it into http, but Chrome thinks differently
    else
      p
    end
  end
  
  def uri(url)
    uri = url.match(PROXY)
    { # next string need to keep compatibility with previous created code
      scheme:   uri[:scheme] == 'socks' ? 'socks5' : uri[:scheme],
      username: uri[:username],
      password: uri[:password],
      host:     uri[:host],
      port:     uri[:port]
    }
  end
  
  def count
    @proxies.count
  end
end
