require_relative '../lib/parser'
require_relative '../lib/keeper'

class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @data_array = []
    @parser = Parser.new
    @keeper = keeper
  end
  
  def scrape_new_data
    index_page = connect_to("https://www.fdic.gov/news/press-releases/index.html")
    year = parser.get_current_html_year(index_page.body)
    get_json_pages(year)
  end

  def scrape_inner_page(link)
    file_name = Digest::MD5.hexdigest link
    page = connect_to(link)
    save_file_year(page, file_name, "#{keeper.run_id}_pages")
  end

  def scrape_archive_data(year)
    page = connect_to("https://www.fdic.gov/news/press-releases/#{year.to_s}/")
    save_file_year(page, "outer_page_#{year.to_s}", "#{keeper.run_id}_pages")
    parser.get_inner_links(page.body)
  end

  private

  attr_accessor :keeper, :parser

  def get_json_pages(year)
    data_source_url = "https://www.fdic.gov/news/press-releases/#{year.to_s}/press-releases.json"
    page = connect_to(data_source_url)  
    save_file_year(page, "outer_page_#{year.to_s}", "#{keeper.run_id}_pages")
    parser.get_json_inner_links(page.body)
  end

  def save_file_year(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def search_headers
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1"
    }
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, headers: search_headers, proxy_filter: @proxy_filter){ |resp| resp.headers[:content_type].match?(%r{octet-stream|text|html|json}) }
      if [301, 302].include? response&.status
        url = response.headers["location"]
        response = connect_to(url)
        return
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end
end
