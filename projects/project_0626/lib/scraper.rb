# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
    @proxies = PaidProxy.where(is_socks5: 1).to_a
    @proxy = @proxies.sample
    proxy_addr = @proxy[:ip]
    proxy_port = @proxy[:port]
    proxy_user = @proxy[:login]
    proxy_passwd = @proxy[:pwd]
    socks_proxy = "socks://#{proxy_user}:#{proxy_passwd}@#{proxy_addr}:#{proxy_port}"
    @agent.agent.set_proxy(socks_proxy)
  end

  def main_page
    content = @agent.get("https://www.jud.ct.gov/attorneyfirminquiry/AttorneyFirmInquiry.aspx")
    Hamster.logger.debug(content.code)
    content.body
  end

  def search_page(params)
    content = @agent.post("https://www.jud.ct.gov/attorneyfirminquiry/AttorneyFirmInquiry.aspx",  params)
    Hamster.logger.debug(content.code)
    content.body
  end
end
