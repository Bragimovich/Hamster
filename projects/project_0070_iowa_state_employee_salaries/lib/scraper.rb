# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize
    super
    @cookie = {}
  end

  def cookies
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def connect_to(*arguments, &block)
    arguments.first.merge!({cookies: {"cookie" => cookies} }) unless @cookie.empty?
    @raw_content      = Hamster.connect_to(*arguments, &block)
    @content_html     = Nokogiri::HTML(@raw_content.body)
    set_cookie @raw_content.headers["set-cookie"]
    @raw_content 
  end

  def set_cookie raw_cookie
    return if raw_cookie.nil?
    raw = raw_cookie.split(";").map do |item|

      if item.include?("Expires=")
        item.split("=")
        ""
      else
        item.split(",")
      end

    end.flatten
    raw.each do |item|
      if !item.include?("Path") && !item.include?("HttpOnly")  && !item.include?("Secure") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
  end

  def main_page
    result = connect_to(url: "https://www.legis.iowa.gov/publications/fiscal/salaryBook")
    years = @content_html.css('select#fiscalYearSelect').children.map {|a| a.attr('value')}.drop(1)
    departments = @content_html.css('select')[3].children.map {|a| a.attr('value')}.drop(1)

    {
      years: years,
      departments: departments
    }
  end

  def send_request(year, department)
    req_body = "fy=#{year}&aid=#{department}"
    connect_to(url: "https://www.legis.iowa.gov/publications/fiscal/salaryBook", req_body: req_body, method: :post)
    if @content_html.css('.main').css('h3').text.include?("Web Page Blocked!")
      @logger.debug(@content_html.css('.main').css('h3').text)
      send_request(year, department)
    end
    @raw_content 
  end
end
