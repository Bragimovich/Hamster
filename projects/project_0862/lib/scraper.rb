# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize(options)
    super
    @agent = Mechanize.new
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.user_agent_alias = 'Mac Safari'
    @proxies = PaidProxy.where(is_socks5: 1).where(locked_to_scrape07: 0).to_a
    swap_proxy
  end

  def swap_proxy
    @proxy = @proxies.sample
    proxy_addr = @proxy[:ip]
    proxy_port = @proxy[:port]
    proxy_user = @proxy[:login]
    proxy_passwd = @proxy[:pwd]
    socks_proxy = "socks://#{proxy_user}:#{proxy_passwd}@#{proxy_addr}:#{proxy_port}"
    @agent.agent.set_proxy(socks_proxy)
  end

  def main_page
    content =  @agent.get("https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf")
    content.body
  end

  def search_page(code, let_first, let_last)
    params = {

      'home_form:j_id_1y' => '',
      'home_form:j_id_23' => "#{let_first}",
      'home_form:j_id_25' => "#{let_last}",
      'home_form:search_btn' => ' Search ',
      'home_form_SUBMIT' => '1',
      'javax.faces.ViewState' => "#{code}"
      }
    content =  @agent.post("https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf", params)
    content.body
  end


  def view_inmate(value, code)
    params = {
      'home_form_SUBMIT' => '1',
      'javax.faces.ViewState' => "#{code}",
      'home_form:_idcl' => "#{value}"
    }
    content =  @agent.post("https://a073-ils-web.nyc.gov/inmatelookup/pages/search_result/results.jsf", params)
    content.body
  end
end
