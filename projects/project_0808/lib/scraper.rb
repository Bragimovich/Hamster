# frozen_string_literal: true

class Scraper < Hamster::Scraper
  SEARCH_URL = "http://docpub.state.or.us/OOS/searchCriteria.jsf"

  def initialize
    super
    @cookie = {}
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def main_request
    connect_to(url: SEARCH_URL, headers: main_request_headers, method: :get, proxy_filter: @proxy_filter)
  end

  def search_request(letters, cookie, js_viewState, offender_id, more_offender_flag)
    connect_to(url: SEARCH_URL, headers: search_request_headers(cookie), req_body: set_search_form_data(letters, js_viewState, offender_id, more_offender_flag), method: :post, proxy_filter: @proxy_filter)
  end
  
  def set_search_form_data(letters, js_viewState, offender_id, more_offender_flag)
    f_name = letters[0] + "*"
    l_name = letters[1..-1] + "*"
    form_data = {
      "mainBodyForm:FirstName" => f_name,
      "mainBodyForm:MiddleName" => "",
      "mainBodyForm:LastName" => l_name,
      "mainBodyForm:SidNumber" => "",
      "javax.faces.ViewState" => js_viewState,
      "mainBodyForm" => "mainBodyForm"
    }   
    if offender_id.empty?
      if more_offender_flag
        form_data.merge!(
          "mainBodyForm:j_id23.x" => "3",
          "mainBodyForm:j_id23.y" => "5",
          "mainBodyForm:j_idcl" => ""
        )
      else
        form_data.merge!(
          "mainBodyForm:sendQuery" => "Search"
        )
      end
    else
      form_data.merge!(
        "mainBodyForm:j_idcl" => offender_id
      )
    end
    form_data.to_a.map { |val| val[0] + "=" + val[1].to_s }.join("&")
  end

  private

  def main_request_headers
    {
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language" => "en-US,en;q=0.9,ur;q=0.8",
    "Connection" => "keep-alive",
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "Upgrade-Insecure-Requests" => "1"
    }
  end

  def search_request_headers(cookie)
    set_cookie(cookie)
    main_headers = main_request_headers
    additional_headers = {
      "Cookie" => cookies,
      "Origin" => "https://docpub.state.or.us",
      "Referer" => "https://docpub.state.or.us/OOS/searchCriteria.jsf",
    }
    main_headers.merge(additional_headers)
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
      logger.info status 
    else
      logger.error status 
    end
    logger.info '=================================='
  end

end
