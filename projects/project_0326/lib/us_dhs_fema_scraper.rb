require_relative '../lib/us_dhs_fema_parser'
require_relative '../models/us_dhs_fema'

class UsDhsFemaScraper < Hamster::Scraper
  def initialize(run_id)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @run_id       = run_id
    @user_agents  = UserAgent.where(device_type: 'Desktop User Agents').pluck(:user_agent)
    UserAgent.connection.close
  end

  attr_reader :count

  def start
    3.times do |page_num|
      url       = "https://www.fema.gov/about/news-multimedia/press-releases?page=#{page_num}"
      page      = get_body_of_page(url)
      parse     = UsDhsFemaParser.new(page)
      links     = parse.get_links
      new_links = links.select { |link| UsDhsFema.find_by(link: link).nil? }
      new_links.each do |link|
        article_page = get_body_of_page(link)
        save_file(article_page, link)
      end
    end
  end

  private

  attr_reader :run_id

  def get_body_of_page(link)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false, headers: { user_agent: @user_agents.sample })
  end

  def connect_to(*arguments)
    10.times do
      response = super(*arguments)
      return response.body if [200, 304].include?(response&.status)
    end
  end

  def save_file(html, link)
    md5 = Digest::MD5.new
    md5.update link
    name = md5.hexdigest
    peon.put(content: html, file: name, subfolder: "#{run_id}_pages")
    @count += 1
  end
end
