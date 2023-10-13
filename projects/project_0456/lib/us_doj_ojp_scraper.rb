require_relative '../lib/us_doj_ojp_parser'

class UsDojOjpScraper < Hamster::Scraper

  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @sub_folder = "RunId_#{keeper.run_id}"
  end
  
  def save_html_pages
    page = connect_to("https://www.ojp.gov/news/news-releases")
    save_file(page, "outer_page")
    page.body
  end

  def process_inner_pages(inner_link, file_name)
    page = connect_to(inner_link)
    save_file(page, file_name)
  end

  private

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      if [301, 302].include? response&.status
        url = response.headers["location"]
        response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: @sub_folder
  end
end
