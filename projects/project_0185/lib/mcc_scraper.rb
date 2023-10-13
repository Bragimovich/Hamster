require_relative 'mcc_keeper'

class MccScraper < Hamster::Scraper
  TASK_NAME = "#185 Millennium Challenge Corporation"
  SLACK_ID  = 'Eldar Eminov'
  HOST      = 'www.mcc.gov'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
  end

  def scrape
    keeper   = MccKeeper.new
    links_db = keeper.links
    types    = %w[releases speeches slideshows]
    types.each do |type|
      3.times do |idx|
        url        = "https://www.mcc.gov/news-and-events/#{type}?fwp_paged=#{idx + 1}"
        page       = get_body_of_page(url)
        parser     = MccParser.new(html: page)
        links      = parser.get_news_links
        start_info = parser.parse_start_info if type == 'slideshows'
        new_links  = links - links_db
        new_links.each do |link|
          sleep(rand(0.3..1))
          article_page = get_body_of_page(link)
          md5 = MD5Hash.new(columns: %i[link])
          md5.generate({link: link})
          file_name = md5.hash
          if type == 'slideshows'
            file_name = "slideshows_#{file_name}"
            txt_content = start_info.find { |i| i[:link] = link }[:date]
            peon.put(content: txt_content, subfolder: type, file: "#{file_name}.txt")
          end
          peon.put(content: article_page, file: file_name)
        end
      end
    end
  end

  private

  def get_body_of_page(link)
    connect_to(url: link, proxy_filter: @proxy_filter, ssl_verify: false, method: :get)&.body
  end
end
