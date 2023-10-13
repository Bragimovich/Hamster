require "socksify/http"
require 'faraday'

class Faraday::Adapter::NetHttp
  def net_http_connection(env)
    if (proxy = env[:request][:proxy])
      proxy_class(proxy)
    else
      Net::HTTP
    end.new(env[:url].hostname, env[:url].port || (env[:url].scheme == "https" ? 443 : 80))
  end

  def proxy_class(proxy)
    if proxy.uri.scheme == "socks"
      TCPSocket.socks_username = proxy[:user] if proxy[:user]
      TCPSocket.socks_password = proxy[:password] if proxy[:password]
      Net::HTTP::SOCKSProxy(proxy[:uri].host, proxy[:uri].port)
    else
      Net::HTTP::Proxy(proxy[:uri].host, proxy[:uri].port, proxy[:uri].user, proxy[:uri].password)
    end
  end
end


def get_site (url_get)
  uri = URI.parse('socks://iHtfgW31135:hgZxWDvOhE@102.129.207.74:4294')

  connection = Faraday.new(url: url_get,
                           proxy: uri) do |c|
    c.headers[:user_agent] = "Just Some Engineer"
    c.adapter :net_http
    c.response :logger
  end

  response = connection.get
  return response.body

end

