
class Scraper < Hamster::Scraper
  attr_reader :page, :data_source, :year_1, :year_2

  URL_BASE = "https://www.irs.gov/statistics/soi-tax-stats-migration-data"

  def initialize
    super
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
    @data_source = URL_BASE
  end

  def download
    @proxies = PaidProxy.where(is_socks5: 1).to_a
    @proxy = @proxies.sample
    proxy_addr = @proxy[:ip]
    proxy_port = @proxy[:port]
    proxy_user = @proxy[:login]
    proxy_passwd = @proxy[:pwd]


    socks_proxy = "socks://#{proxy_user}:#{proxy_passwd}@#{proxy_addr}:#{proxy_port}"
    @agent.agent.set_proxy(socks_proxy)

    @page = @agent.get(URL_BASE)
    body_parse = @page.parser
    li_els = body_parse.xpath('//div[@class="accordion-list"]//li')
    _, @year_1, @year_2 = li_els[0].text.match(/(\d{4})\sto\s(\d{4})/).to_a
    url_csv = li_els.first.css("a").attr('href').value
    url_csv = "https://www.irs.gov" + url_csv

    @page = @agent.get(url_csv)
    body_parse = @page.parser

    selector = body_parse.xpath('//p/b[text()=".csv Files"]').empty? ? 'div/h3' : 'p/b'

    link_inflow = body_parse.xpath("//#{selector}[text()='.csv Files']//..//a[text()='County-to-County Inflow']").attr("href").value
    link_outflow = body_parse.xpath("//#{selector}[text()='.csv Files']//..//a[text()='County-to-County Outflow']").attr("href").value

    file_inflow = @agent.get_file(link_inflow)
    peon.put(file: "inflow.csv", content: file_inflow)
    file_outflow = @agent.get_file(link_outflow)
    peon.put(file: "outflow.csv", content: file_outflow)

  end
end
