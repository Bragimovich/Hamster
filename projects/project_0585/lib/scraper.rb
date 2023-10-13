require 'faraday'
require_relative 'connector'
class Scraper <  Hamster::Scraper
  BASE_URL    = "https://api.secure.tributecenteronline.com"
  CONFIRM_URL = 'https://api.secure.tributecenteronline.com/archiveapi/Scraper/Confirm'

  def initialize
    super
    @connector = TributeConnector.new(BASE_URL)
    @proxy = Camouflage.new()
    @current_proxy = @proxy.swap
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 30000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def scrape(from_date = Date.today - 3.days, end_date = Date.today)
    page_size = 1000
    page_number = 1
    obituary_data = []
    loop do
      search_data = "pageSize=#{page_size}&pageNumber=#{page_number}&dateStart=#{from_date}&dateEnd=#{end_date}"
      response = @connector.do_connect("#{BASE_URL}/archiveapi/obituarysearch/?#{search_data}")
      body = JSON.parse(response.body)
      logger.info("page: #{page_number}, searchResult: #{body['searchResult'].count}")
      obituary_data << body['searchResult']
      page_number += 1

      break unless body['hasNextPage']
    end
    obituary_data.flatten
  end

  def get_request(url, access_token)
    logger.info "Processing URL (GET REQUEST) -> #{url}"
    conn = Faraday.new(:url => BASE_URL) do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get do |req|
      req.url "#{resource}"
      req.headers['Authorization'] = "Bearer #{access_token}" if access_token.present?
    end
    reporting_request(response)
    [response, response.status]
  end

  def download_page(url)
    retries = 0
    begin
      logger.debug "download_page Processing URL -> #{url}"
      begin
        response = connect_to(url: url , proxy_filter: @proxy_filter)
      rescue NoMethodError
        return [nil, 404]
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end
end
