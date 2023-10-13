require_relative 'hhs_parser'
require_relative 'hhs_database'

class Scraper < Hamster::Scraper

  def initialize(year=0, update=0)
    #existing_links(year).each {|q| p q}
    @update = update
    p @update
    if year>2020
      scrape_news_2021
    elsif year==0

      year = 2020
      while year!=1990
        p year
        scrape_news_until_2021(year)
        year=year-1
      end
      scrape_news_2021
    elsif year<2021 && year>1990
      scrape_news_until_2021(year)
    end


  end


  URLS = {
    1991 => 'http://web.archive.org/web/20100610045233/http://archive.hhs.gov/news/press/1991.html',
    1992 => 'http://web.archive.org/web/20100610044305/http://archive.hhs.gov/news/press/1992.html',
    1993 => 'http://web.archive.org/web/20100610042303/http://archive.hhs.gov/news/press/1993.html',
    1994 => 'http://web.archive.org/web/20100610042308/http://archive.hhs.gov/news/press/1994.html',
    1995 => 'http://web.archive.org/web/20100610042314/http://archive.hhs.gov/news/press/1995.html',
    1996 => 'http://web.archive.org/web/20100610045239/http://archive.hhs.gov/news/press/1996.html',
    1997 => 'http://web.archive.org/web/20100610042319/http://archive.hhs.gov/news/press/1997.html',
    1998 => 'http://web.archive.org/web/20100610042324/http://archive.hhs.gov/news/press/1998.html',
    1999 => 'http://web.archive.org/web/20100610044313/http://archive.hhs.gov/news/press/1999.html',
    2000 => 'http://web.archive.org/web/20100610043420/http://archive.hhs.gov/news/press/2000.html',
    2001 => 'http://web.archive.org/web/20100610043425/http://archive.hhs.gov/news/press/2001.html',
    2002 => 'http://web.archive.org/web/20100610045246/http://archive.hhs.gov/news/press/2002.html',
    2003 => 'http://web.archive.org/web/20100608042534/http://archive.hhs.gov/news/press/2003.html',
    2004 => 'http://web.archive.org/web/20100610044206/http://archive.hhs.gov/news/press/2004.html',
    2005 => 'http://web.archive.org/web/20060201191353/http://www.hhs.gov/news/press/2005.html',
    2006 => 'http://web.archive.org/web/20090109045805/http://www.hhs.gov/news/press/2006pres/2006.html',
    2007 => 'http://web.archive.org/web/20080206215458/http://hhs.gov/news/press/2007pres/2007.html',
    2008 => 'http://web.archive.org/web/20090201023832/http://www.hhs.gov/news/press/2008pres/2008.html',
    2009 => 'http://web.archive.org/web/20100226065444/http://www.hhs.gov/news/press/2009pres/2009.html',
    2010 => 'http://web.archive.org/web/20110328134807/http://www.hhs.gov/news/press/2010pres/2010.html',
    2011 => 'https://wayback.archive-it.org/3926/20140108161909/http://www.hhs.gov/news/press/2011pres/2011.html',
    2012 => 'https://wayback.archive-it.org/3926/20150121155151/http://www.hhs.gov/news/press/2012pres/2012.html',
    2013 => 'http://web.archive.org/web/20160113084618/http://www.hhs.gov/about/news/2013-news-releases',
    2014 => 'http://web.archive.org/web/20160320105610/http://www.hhs.gov/about/news/2014-news-releases',
    2015 => 'http://web.archive.org/web/20160111144541/http://www.hhs.gov:80/about/news/2015-news-releases',
    2016 => 'http://web.archive.org/web/20170124230203/https://www.hhs.gov/about/news/2016-news-releases/index.html',
    2017 => 'http://web.archive.org/web/20180427010823/https://www.hhs.gov/about/news/2017-news-releases/index.html',
    2018 => 'http://web.archive.org/web/20190120012901/https://www.hhs.gov/about/news/2018-news-releases/index.html',
    2019 => 'http://web.archive.org/web/20200506193033/https://www.hhs.gov/about/news/2019-news-releases/index.html',
    2020 => 'http://web.archive.org/web/20210116115241/https://www.hhs.gov/about/news/2020-news-releases/index.html'
  }


  def scrape_news_2021(page=0, year=2022)
    array_of_news = []
    old_links = existing_links(year)

    q = 0
    loop do
      url = "https://www.hhs.gov/about/news/index.html?_wrapper_format=html&content_type=All&page=#{page}"
      site = connect_to(url:url)
      p "PAGE: #{page}"
      #begin
        list_news_short = parse_list_news(site.body)
      # rescue => e
      #   puts e
      #   redo
      #   return array_of_news if q==5
      #   q+=1
      # end
      o = 0

      break if list_news_short.empty?

      list_news_short.each do |news_short|
        news_short[:link] = 'https://www.hhs.gov' + news_short[:link]
        next if news_short[:link].in?(old_links)
        short_title = news_short[:title].split(' ').map{ |o| o[0].downcase}.join('')
        # next if existing_ids.include?(news[:prlog_id])

        news_html_page = connect_to(news_short[:link]).body
        news_long = parse_one_news(news_html_page)
        full_news = news_long.update(news_short)
        full_news[:dirty]=0 if full_news[:dirty].nil?
        full_news[:md5_hash] = make_md5(full_news)
        put_date(full_news) if !existing_md5_hash(full_news[:md5_hash])
        # break if o==3
        o+=1
        # next if !news_long
        # news_full = news_long.merge(news_short)
        # array_of_news.push(news_full)
      end
      break if o<10 and @update!=0
      page += 1
    end
    p 'END'
    array_of_news
  end

  #url = 'https://public3.pagefreezer.com/browse/HHS.gov/31-12-2020T08:51/https://www.hhs.gov/about/news/2019-news-releases'
  def scrape_news_until_2021(year=2020)
    old_links = existing_links(year)
    site = connect_to(url:URLS[year])
    p URLS[year]
    case year
    when (2013..2021)
      list_news_short = parse_list_news_2013_2020(site.body, year)
    when 2012
      list_news_short = parse_list_news_2012(site.body)
    when 2011
      list_news_short = parse_list_news_2011(site.body)
    when (2009..2010)
      list_news_short = parse_list_news_2009_2010(site.body)
    when (2006..2008)
      list_news_short = parse_list_news_2006_2008(site.body)
    when 2005
      list_news_short = parse_list_news_2005(site.body)
    when (2003..2005)
      list_news_short = parse_list_news_2002_2005(site.body, year)
    when 2002
      list_news_short = parse_list_news_2002(site.body, year)

    when (1991..2001)
      list_news_short = parse_list_news_2001(site.body, year)
    end

    agent = get_agent

    break_n = 0
    p list_news_short
    list_news_short.each do |news_short|
      next if news_short[:link].nil?
      case year
      when (2013..2021)
        news_short[:link] = "http://web.archive.org#{news_short[:link]}"
      when (2011..2012)
        news_short[:link] = "https://wayback.archive-it.org#{news_short[:link]}"
      when (1991..2011)
        news_short[:link] = URLS[year].split(".org/")[0]+'.org' + news_short[:link]
      end

      next if news_short[:link].in?(old_links) || !news_short[:link].match('hhs.gov')
      p news_short
      begin
        news_html_page = agent.get(news_short[:link]).body
      rescue => error
        File.open("logs/proj_93", "a") do |file|
          file.write("#{Date.today.to_s}| #{news_short[:link]} : #{error.to_s} \n")
        end
        next
      end
      #begin
        case year
        when (2016..2021)
          news_long = parse_one_news_2016_2020(news_html_page)
          news_long[:dirty]=0
        when (2013..2016)
          news_long = parse_one_news_2013_2015(news_html_page)
          news_long[:dirty]=0
        when 2012
          news_long = parse_one_news_2012(news_html_page)
          news_long[:dirty]=0
        when (2009..2011)
          news_long = parse_one_news_2009_2011(news_html_page)
        when (2006..2008)
          news_long = parse_one_news_2006_2008(news_html_page)
        when (2003..2005)
          news_long = parse_one_news_2003_2005(news_html_page)
        when (1999..2002)
          news_long = parse_one_news_1999_2002(news_html_page)
          news_long[:dirty]=1
        when (1995..1998)
          news_long = parse_one_news_1995_1998(news_html_page, year)
          news_long[:dirty]=1
        when (1991..1994)
          news_long = parse_one_news_1991_1994(news_html_page, year)
          news_long[:dirty]=1
        end
      # rescue => error
      #   File.open("logs/proj_93", "a") do |file|
      #     file.write("#{Date.today.to_s}| #{news_short[:link]} : #{error.to_s} \n")
      #   end
      #   next
      # end

      full_news = news_long.update(news_short)
      full_news[:md5_hash] = make_md5(full_news)
      p full_news
      put_date(full_news)
      # break if break_n>9
      # break_n+=1
    end

  end


  def make_md5(news_hash)
    all_values_str = ''
    columns = %i[title link date]
    columns.each do |key|
      if news_hash[key].nil?
        all_values_str = all_values_str + news_hash[key.to_s].to_s
      else
        all_values_str = all_values_str + news_hash[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end

  def get_agent

    pf = ProxyFilter.new
    begin

      proxy = PaidProxy.where(is_http: 1).where(ip: '45.72.97.42').to_a.shuffle.first

      raise "Bad proxy filtered" if pf.filter(proxy).nil?

      agent = Mechanize.new#{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}

      agent.user_agent_alias = "Windows Mozilla"
      agent.set_proxy(proxy.ip, proxy.port, proxy.login, proxy.pwd)

    rescue => e
      print Time.now.strftime("%H:%M:%S ").colorize(:yellow)
      puts e.message.colorize(:light_white)

      pf.ban(proxy)
      retry
    end

    agent
  end

end