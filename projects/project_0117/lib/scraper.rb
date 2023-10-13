require 'nokogiri'
require 'securerandom'

class Scraper < Hamster::Scraper
  LINK = "https://www.dhs.gov/news-releases/press-releases?combine=&created=&field_taxonomy_topics_target_id=All&items_per_page=50&sort_bef_combine=created_DESC"
  LINK_AJAX = ""
  LINK_PAGE = "?search_api_views_fulltext=&"
  URL_BASE = "https://www.dhs.gov"
  LINK_ARCHIVE_TMP_BASE = "https://www.dhs.gov/archive/news-releases/press-releases?combine=&created=&field_taxonomy_topics_target_id=All&items_per_page=50&sort_bef_combine=created_DESC&page=%s"
  #combine=&created=&field_taxonomy_topics_target_id=All&items_per_page=50&sort_bef_combine=created_DESC

  def initialize(*_)
    super
    @array_link = []
    start_page = URL_BASE + "/news-releases/press-releases"
    @cookie = {}

  end


  # Cookie work
  def cookies
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def connect_to(*arguments, &block)
    if arguments.first.class == Hash
      arguments.first.merge!({cookies: {"cookie" => cookies} }) unless @cookie.empty?
    else
      url = arguments.first
      arguments[0] = ({url: url, cookies: {"cookie" => cookies} }) unless @cookie.empty?
    end
    @raw_content      = Hamster.connect_to(*arguments, &block)
    @content_raw_html = @raw_content.body
    @content_html     = Nokogiri::HTML(@content_raw_html)
    @raw_set_cookie   = @raw_content.headers["set-cookie"]
    set_cookie @raw_set_cookie
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
      if !item.include?("Path") && !item.include?("HttpOnly")  && !item.include?("Secure") && !item.include?("Domain") && !item.include?("Max-Age") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
  end

  def down_pages
    if @array_link.size > 0
      @array_link.each do |link|
        link_url = link
        page = connect_to(link_url)

        name = SecureRandom::hex(6) + ".html"
        if !page.body.nil? and !page.body.empty?
          content = page.body + "<link>#{link_url}</link>"
          peon.put(file: name, subfolder: @folder, content: content)
        end
      end
    else
      puts "No link on page"
    end
  end

  def download
    @folder = "current"
    page = connect_to(LINK)
    html = @content_html
    number_last_page = 1
    number_last_page = html.css("nav.usa-pagination ul.usa-pagination__list>li")[-2].css("a").attr("href").value.scan(/\&page=(\d+)/).flatten.first.to_i if html.css("nav.usa-pagination ul.usa-pagination__list>li").size > 0
    $page = 1
    while $page <= number_last_page
      pages = html.css("div.view-content li.usa-collection__item").map {|item| item.css("a @href").text}
      if pages.size > 0
        pages.each do |link|
          @array_link.push(URL_BASE + link)
        end
      end
      page = connect_to(LINK + "&page=" + $page.to_s)
      $page += 1
    end
    down_pages
  end

  def download_archive
    @folder = "archive"
    link = sprintf(LINK_ARCHIVE_TMP_BASE, "0")
    page = connect_to(link)
    html = Nokogiri.HTML(page.body)
    link_last_page = html.css("div.item-list li.pager-last a")[0].attr("href")
    number_last_page = link_last_page.match(/\&page=(\d+)/)[1].to_i
    $page = 1
    while $page <= number_last_page
      pages = html.css("div.view-content div.views-row")
      if pages.size > 0
        pages.each do |index|
          link = index.css("a").attr("href").value
          @array_link.push(URL_BASE + link)
        end
      end
      link = sprintf(LINK_ARCHIVE_TMP_BASE, $page.to_s)
      page = connect_to(link)
      html = Nokogiri.HTML(page.body)
      $page += 1
    end
    down_pages
  end
end