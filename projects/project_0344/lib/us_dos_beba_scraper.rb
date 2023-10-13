require_relative 'us_dos_beba_parser'

class UsDosBebaScraper < Hamster::Scraper
  ACCEPT     = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'

  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @run_id       = keeper.run_id
    @keeper       = keeper
    @count        = 0
    @proxies      = get_proxies
  end

  attr_reader :count

  def start
    page_num = 1
    parser   = UsDosBebaParser.new
    while true do
      logger.debug "Page #{page_num}".green
      url = "https://www.state.gov/remarks-and-releases-bureau-of-economic-and-business-affairs/page/#{page_num}/"
      url = url.sub!(/page\/1\/$/, '') if page_num == 1
      list_page  = get_response(url)
      links_site = parser.list(list_page, :links)
      links_sort = keeper.get_links_not_in_db(links_site)
      peon.put(file: "page_#{page_num}", content: list_page, subfolder: "#{run_id}_pages_of_list") if links_sort.any?
      save_article_page(links_sort)
      break if links_site.empty? || links_sort.empty?

      page_num += 1
    end
  end

  private

  attr_reader :run_id, :keeper

  def save_article_page(links)
    links.each do |link|
      article_page = get_response(link)
      sleep(rand(0.2..0.7))
      md5 = MD5Hash.new(columns: %i[link])
      md5.generate({link: link})
      file_name = md5.hash
      peon.put(file: file_name, content: article_page, subfolder: "#{run_id}_article_pages")
      @count += 1
    end
  end

  def get_response(link)
    headers = { accept: ACCEPT, accept_language: 'en-GB,en;q=0.9' }
    link.sub!('/people/', '/biographies/') if link.include?('/people/')
    @proxy_filter.ban_reason = proc { |response| ![200, 304, 301].include?(response.status) || response.body.size.zero? }
    response = connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false, headers: headers, proxy: @proxies)
    if response&.status == 403
      proxy = response.env.request.proxy.uri.to_s
      logger.debug 'Deleted proxy: '.yellow + "#{proxy}".red
      @proxies -= [proxy]
      raise 'There are no working proxies left' if @proxies.empty?
      response = get_response(link)
    end
    if response.nil? || (response.class == String && response.size < 400) || (response == Faraday::Response && response.body.size < 400)
      message = "#{response&.status} | #{proxy} | Stopped"
      logger.error message.red
      Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{message}", use: :both)
    end
    response.class == String ? response : response&.body
  end

  def connect_to(*arguments)
    response = nil
    5.times do
      response = super(*arguments)
      break if [200, 304, 301, 403].include?(response&.status)
    end

    response = connect_repeat(response, arguments) { super } if response&.status == 403
    response = connect_redirect(response, arguments) if response&.status == 301
    response
  end

  def connect_redirect(response, arguments)
    redirect_link = response.headers['location']
    arguments[0]  = redirect_link
    connect_to(*arguments)
  end

  def connect_repeat(response, arguments)
    proxy = response.env.request.proxy.uri.to_s
    arguments.last[:proxy] = proxy
    2.times do |i|
      sleep rand(0.2..0.6)
      response = yield(*arguments)
      break if [200, 304, 301].include?(response&.status)

      logger.debug "Error status #{response&.status} | Try #{i} | #{proxy}".red
    end
    response
  end

  def get_proxies
    proxies = PaidProxy.all.pluck(:ip, :port, :login, :pwd, :is_socks5).shuffle
    PaidProxy.connection.close
    proxies.map { |p| "#{p.at(4) ? 'socks' : 'https'}://#{p.at(2)}:#{p.at(3)}@#{p.at(0)}:#{p.at(1)}" }
  end
end
