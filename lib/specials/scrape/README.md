**Files**

mechanize/http/agent/mechanize_http_agent.rb

net_http/persistent/net_http_persistent.rb

**Example how use**:

@agent = Mechanize.new

@agent.agent.set_proxy("socks://#{socks_username}:#{socks_password}@#{socks_address}:#{socks_port}")

@agent.get(some_url_site)

_January 2023_