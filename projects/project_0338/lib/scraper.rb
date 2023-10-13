# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @cookie = {}
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def get_cookie
    url = 'https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/political-committee-fund/'
    response = connect_to(url: url, headers: basic_headers, method: :get, proxy_filter: @proxy_filter)
    response['set-cookie']
  end

  def search_items_list_get_request(cookie, data)
    if data == 'csv'
      url = 'https://cfb.mn.gov/reports-and-data/self-help/data-downloads/campaign-finance/'
    else
      url = 'https://cfb.mn.gov/reports/api/'
    end
    connect_to(url: url, req_body: make_search_item_body(data), headers: make_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def candidate_post_request(id, year, cookie, tab_name)
    url = 'https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/candidates/api'
    connect_to(url: url, req_body: make_request_body(id, year, tab_name), headers: make_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def committee_post_request(id, year, cookie)
    url = 'https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/political-committee-fund/api'
    connect_to(url: url, req_body: make_request_body(id, year, 'information'), headers: make_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def party_post_request(id, year, cookie)
    url = 'https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/party-unit/api'
    connect_to(url: url, req_body: make_request_body(id, year, 'information'), headers: make_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def download_csv_file(url, file_path)
    connect_to(url, method: :get_file, filename: file_path)
  end
  private

  def make_search_item_body(data)
    form_data = {
      'action' => 'searchbox',
      'data[action]' => data
    }
    form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
  end

  def make_request_body(id, year, tab_name)
    form_data = {
      'id' => id,
      'year' => year.to_s,
      'year_data[ElectionSegmentEndDate]' =>	year.to_s,
      'year_data[ElectionSegmentStartDate]'	=> (year - 1).to_s,
      'tabname' => tab_name
    }
    form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
  end

  def basic_headers
    {
      "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0",
      "Accept" =>   "application/json, text/plain, */*",
      "Accept-Language" => "en-US,en;q=0.5",
      "Connection" => "keep-alive",
      "Origin" => "https://cfb.mn.gov",
      "Dnt" => "1",
      "Upgrade-Insecure-Requests" => "1"
    }
  end

  def make_headers(cookie)
    set_cookie(cookie)
    headers = basic_headers
    headers["Referer"] = "https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/"
    headers["Cookie"] = cookies
    headers
  end

  def set_cookie(raw_cookie)
    raw = raw_cookie.split(";").map do |item|
      item.split(",")
    end.flatten
     
    raw.each do |item|
      if !item.include?("path") && !item.include?("samesite")  && !item.include?("httponly") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
  end
 
  def cookies
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    logger.info '=================================='
    logger.info 'Response status: '.indent(1, "\t")
    status = response&.status
    if status == 200
      logger.info  status 
    else
      logger.error status 
    end
    logger.info '=================================='
  end

end
