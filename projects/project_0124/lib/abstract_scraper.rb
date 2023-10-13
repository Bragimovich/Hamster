
class AbstractScraper < Hamster::Scraper
  attr_reader :raw_content, :content_raw_html, :content_html, :cookie

  def initialize(option = nil)
    super
    @cookie = {} #An object with cookies
    @headers = "" #An object with header parameters
    @accept = {
      "html" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "json" => "application/json, text/javascript, */*; q=0.01",
      "pdf" => "application/pdf",
      "url_post" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
    }

    @content_type = {
      "html" => "text/html",
      "json" => "application/json",
      "pdf" => "application/pdf",
      "url_post" => "application/x-www-form-urlencoded"
    }

  end

  def delete_cookie
    @cookie = {}
  end

  def header(*options)

    arguments = options.first.dup
    accept = arguments[:accept]

    @headers = {
      "Accept" => @accept[accept],
      "Accept-Encoding" => "gzip, deflate, br",
      "Referer" => "https://www.iardc.org/Lawyer/SearchResults",
      "Origin" => "https://www.iardc.org",
      "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
      "Content-Type" => @content_type[accept],
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Pragma" => "no-cache",
      "Cache-Control" => "no-cache"
    }
    #POST /publicAccess/html/common/index.xhtml HTTP/1.1
    # Host: circuitclerk.lakecountyil.gov
    # User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0
    # Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
    # Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3
    # Accept-Encoding: gzip, deflate, br
    # Content-Type: application/x-www-form-urlencoded
    # Content-Length: 1247
    # Origin: https://circuitclerk.lakecountyil.gov
    # Connection: keep-alive
    # Referer: https://circuitclerk.lakecountyil.gov/publicAccess/html/common/index.xhtml
    # Cookie: JSESSIONID=6122262A25AAC63611EED2F0A840F03C

    @headers.merge!({ "X-Requested-With" => "XMLHttpRequest" }) if accept == "json"

  end

  def cookies
    @cookie.map { |key, value| "#{key}=#{value}" }.join(";")
  end

  def connect_to(*arguments, &block)
    arguments.first.merge!({ cookies: { "cookie" => cookies }, headers: @headers }) unless @cookie.empty?

    @raw_content = Hamster.connect_to(*arguments, &block)

    unless @raw_content.status == 302
      @content_raw_html = @raw_content.body
      @content_html = Nokogiri::HTML(@content_raw_html)
      @raw_set_cookie = @raw_content.headers["set-cookie"]
      set_cookie @raw_set_cookie
    end
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
    # raw = raw_cookie.split(";").first
    raw.each do |item|
      if !item.include?("Path") && !item.include?("HttpOnly") && !item.include?("Secure") && !item.include?("secure") && !item.include?("Domain") && !item.include?("path") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({ "#{name}" => value })
      end
    end

  end

end
