require_relative '../lib/parser'
class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
  end

  attr_reader :count

  def scrape
    links_db    = keeper.db_links
    page_num    = 0
    concurrence = false
    loop do
      break if concurrence

      url    = "https://arpa-e.energy.gov/news-and-media/press-releases?page=#{page_num}"
      page   = get_body_of_page(url)
      parser = Parser.new(html: page)
      links  = parser.get_news_links
      break unless links

      new_links = []
      links.each { |link| links_db.include?(link) ? concurrence = true : new_links << link }
      break if new_links.empty?

      new_links.each do |link|
        sleep(rand(0.3..1))
        article_page = get_body_of_page(link)
        md5          = MD5Hash.new(columns: %i[link])
        md5.generate({ link: link })
        file_name = md5.hash
        peon.put(content: article_page, file: file_name)
        @count += 1
      end
      page_num += 1
    end
  end

  private

  attr_reader :keeper

  def get_body_of_page(link)
    filter = @proxy_filter
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: filter, ssl_verify: false)
  end

  def connect_to(*arguments)
    response = nil
    10.times do
      response = super(*arguments)
      break if response&.status && [200, 304].include?(response.status)
    end
    response&.body
  end
end
