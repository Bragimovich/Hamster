require 'nokogiri'
require 'securerandom'

class Scraper < Hamster::Scraper
  LINK = "https://www.epa.gov/newsreleases/search/year/2022/year/2021?search_api_views_fulltext="
  LINK_PAGE = "?search_api_views_fulltext=&"
  URL_BASE = "https://www.epa.gov"
  LINK_ARCHIVE_TMP = "https://archive.epa.gov/epa/newsroom/%s-news-releases-date.html"
  LINK_ARCHIVE_2014_1994_TMP = "https://archive.epa.gov/epapages/newsroom_archive/newsreleases/%s.html"
  LINK_ARCHIVE_2014_1994_TMP_BASE = "https://archive.epa.gov/epapages/newsroom_archive/newsreleases/"

  def initialize(*_)
    super
    @array_link = []
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
    @folder = "2021_2019"
    page = connect_to(LINK)
    html = Nokogiri.HTML(page.body)

    link_last_page = html.css("nav.pager li a.pager__link.pager__link--last")[0].attr("href")
    number_last_page = link_last_page.match(/page=(\d+)/)[1].to_i

    $page = 1
    while $page <= number_last_page
      pages = html.css("div.l-sidebar-first__main article.teaser")

      if pages.size > 0
        pages.each do |index|
          link = index.css("a").attr("href").value
          @array_link.push(URL_BASE + link)
        end
      end

      page = connect_to(LINK + "&page=" + $page.to_s)
      html = Nokogiri.HTML(page.body)
      $page += 1

    end
    down_pages
  end

  def download_2019_2015
    @folder = "2019_2015"
    @array_link = []
    [2015, 2016, 2017, 2018, 2019].each do |year|
      link = sprintf(LINK_ARCHIVE_TMP, year.to_s)
      page = connect_to(link)
      html = Nokogiri.HTML(page.body);
      tr = html.css("table.striped tbody tr")
      tr.each do |item|
        link_article = item.css("a").attr("href").value
        @array_link.push(link_article)
      end
    end
    down_pages
  end

  def download_2014_1994
    @folder = "2014_1994"
    @array_link = []

    ["index", "2013", "2012", "2011",
     "2010", "2009", "2008", "2007",
     "2006", "2005", "2004", "2003",
     "2002", "2001", "2000", "1999",
     "1998", "1997", "1996", "1995", "1994"].each do |year|
      link = sprintf(LINK_ARCHIVE_2014_1994_TMP, year)
      page = connect_to(link)
      if page.body.nil? or page.body.empty?
        puts "Not page: #{link}"
      else
        html = Nokogiri.HTML(page.body)
        tr = html.css("table tbody tr")
        tr.each do |item|
          unless item.css("a").attr("href").nil?
            url = LINK_ARCHIVE_2014_1994_TMP_BASE + item.css("a").attr("href").value
            @array_link.push(url)
          end
        end
      end
    end
    down_pages
  end

  def download_environment
    @folder = "2021_2019"
    res = UsEpa.where('teaser LIKE "Environmental News%"')
    res.each do |item|
      @array_link.push(item.link)
    end
    down_pages
  end

end