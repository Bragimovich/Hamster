require_relative './parser'
class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
    @user_agents  = UserAgent.where(device_type: 'Desktop User Agents').pluck(:user_agent)
    UserAgent.connection.close
  end

  attr_reader :count

  def scrape
    3.times do |page_num|
      url    = "https://naturalresources.house.gov/news/documentquery.aspx?DocumentTypeID=1634&Page=#{page_num + 1}"
      page   = get_body(url)
      parser = Parser.new(page)
      links  = parser.get_news_links.reject { |link| keeper.link_exist?(link) }
      save_files(links)
    end
  end

  private

  attr_reader :keeper

  def save_files(links)
    links.each do |link|
      page = get_body(link)
      md5  = MD5Hash.new(columns: %i[link])
      name = md5.generate({link: link})
      peon.put(content: page, file: name)
      @count += 1
    end
  end

  def get_body(link)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false, headers: { user_agent: @user_agents.sample })&.body
  end
end
