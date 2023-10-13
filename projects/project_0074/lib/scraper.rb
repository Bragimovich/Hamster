# frozen_string_literal: true

require_relative 'parser'
require_relative 'database'

class Scraper < Hamster::Scraper

  def initialize(year=2021, month=6, day=25, update=0)
    super
    if update == -1
      get_from_old(year, month)
      return
    elsif update == -2
      old_files(year, month)
      return
    elsif update == -3
      fill_tags_articles
      return
    end
    update = 2 if update.class==TrueClass
    date_change(Date.new(year,month,day), update)
    # Cookies problem??
  end


  def get_cookies
    url = 'https://www.prlog.org/news/us/'
    site = connect_to(url)
    cookies_array = site.headers['set-cookie'].split(';')[0].split('=')
    cookies_hash = {cookies_array[0] => cookies_array[1]}
    cookies_hash
  end

  def scrape_news(scrape_date, page=1)
    array_of_news = []
    existing_ids = get_articles_id(scrape_date)

    date_str = "#{scrape_date.year}/#{scrape_date.year}#{scrape_date.month.to_s.rjust(2, '0')}#{scrape_date.day.to_s.rjust(2, '0')}/"
    path_to_save = "#{storehouse}#{scrape_date.year}/#{scrape_date.month.to_s.rjust(2, '0')}/"
    @peon = Peon.new(path_to_save)
    q = 0
    loop do
      #conn = Hamster::Scraper::Dasher.new('https://www.prlog.org/news/us/', using: :cobble, use_proxy:6)
      url = "https://www.prlog.org/news/#{date_str}page#{page}.html"
      site = connect_to(url:url, ssl_verify:false)
      #site = conn.smash(url: url)
      p "PAGE: #{page}"
      begin
        list_news, next_page = parse_list_news(site.body)
      rescue => e
        puts e
        return array_of_news if q==5
        q+=5
        redo
      end
      o = 0
      list_news.each do |news|
        next if existing_ids.include?(news[:prlog_id])
        news[:arcticle_link] = 'https://www.prlog.org' + news[:link]
        site = connect_to(news[:arcticle_link], ssl_verify:false)
        #site = conn.smash(url: news[:arcticle_link])
        if site.nil?
          break if o==5
          o+=1
          redo
        end
        @peon.put(content: site.body, file: news[:prlog_id].to_s)
        news_hash = parse_one_news(site.body)
        #break if o==3
        next if !news_hash
        news_hash[:date] = scrape_date
        news_hash = news_hash.merge(news)
        array_of_news.push(news_hash)
        p news_hash[:prlog_id]

        o=0
      end
      put_articles_to_db(array_of_news, scrape_date) if !array_of_news.empty?
      array_of_news = []
      break if next_page.empty?
      page += 1
    end
    array_of_news
  end


  def date_change(scrape_date = Date.today, update=0)
    last_date = Date.new(2006, 10, 01)
    last_date = scrape_date-update if update>0
    while scrape_date!=last_date
      scrape_date=scrape_date-1
      array_of_news = scrape_news(scrape_date)
      puts "Length for #{scrape_date}: #{array_of_news.length}"
      array_of_news = []
    end
  end

  def get_categories
    url_get = "https://www.prlog.org/news/industry.html"
    site = connect_to(url:url_get)
    doc = Nokogiri::HTML(site.body)
    categories = []
    doc.at_css('.idx').css('td').each do |category|
      categories.push({category: category.content})
    end
    put_categories(categories)
  end

  def get_tags
    url_get = "https://www.prlog.org/news/tag.html"
    site = connect_to(url:url_get)
    doc = Nokogiri::HTML(site.body)
    tags = []
    doc.at_css('.dc').css('a').each do |tag|
      tags.push({tag: tag.content})
    end
    put_tags(tags)
  end

  def get_from_old(year, month)
    while true
      #conn = Hamster::Scraper::Dasher.new('https://www.prlog.org/news/us/', using: :cobble, use_proxy:7)
      path_to_save = "#{storehouse}#{year}/#{month.to_s.rjust(2, '0')}/"
      @peon = Peon.new(path_to_save)
      old_articles = PrlogArticles.where("month(date) = #{month} and year(date) = #{year}")
      ids = old_articles.map { |l| l.prlog_id }
      PrlogArticlesBackup.where("month(date) = #{month} and year(date) = #{year}").each do |article|
        next if article.prlog_id.in? ids
        #site = conn.smash(url: article.arcticle_link)
        site = connect_to(article.arcticle_link, ssl_verify:false)
        next if site.nil?
        @peon.put(content: site.body, file: article.prlog_id.to_s)
        news_hash = parse_one_news(site.body)
        next if (!news_hash) || (news_hash.nil?)
        article.article = news_hash[:article]
        begin
          put_old_articles(article)
        end
      end
      month -= 1
      if month == 0
        year -= 1
        month = 12
      end
      break if year == 2005
    end
  end


  def backup_articles(year, month)
    backup_articles = {}
    PrlogArticlesBackup.where("month(date) = #{month} and year(date) = #{year}").each do |article|
      backup_articles[article.prlog_id] = article
    end
    backup_articles
  end

  def old_files(year, month)

    while true
      path_to_file = "#{storehouse}#{year}/#{month.to_s.rjust(2, '0')}/"
      @peon = Peon.new(path_to_file)

      existing_ids = PrlogArticles.where("month(date) = #{month} and year(date) = #{year}").map { |l| l.prlog_id }
      backup_articles_hash = backup_articles(year, month)
      fs=[]
      @peon.give_list.each do |filename|
        prlog_id = filename.split('.')[0].to_i
        next if prlog_id.in? existing_ids

        fs.push(filename)

        body = @peon.give(file:filename)
        news_hash = parse_one_news(body)
        next if news_hash.nil?
        if backup_articles_hash[prlog_id]
          backup_articles_hash[prlog_id].article = news_hash[:article]
          put_old_articles(backup_articles_hash[prlog_id])
        else
          p "We don't have history for #{prlog_id}"
        end
      end
      p "#{year}/#{month}:#{fs.length}"
      month-=1
      if month==0
        year-=1
        month=12
      end
      break if year==2005
    end

  end


  def fill_tags_articles
    year = 2021
    month=9
    while year!=2005
      while month!=0
        path_to_save = "#{storehouse}#{year}/#{month.to_s.rjust(2, '0')}/"
        p "#{year}/#{month}"
        @peon = Peon.new(path_to_save)
        articles = tags_not_exists(year, month)
        articles.each do |article|
          begin
            body = @peon.give(file: article[:prlog_id].to_s+'.gz')#, subfolder:article[:date].month.to_s.rjust(2, '0'))
          rescue
            body = connect_to(article[:arcticle_link], ssl_verify:false).body
          end
          news = parse_one_news(body)
          next if news.nil?
          news[:prlog_id] = article[:prlog_id]

          put_article_additional(news)
        end
        month = month - 1
      end
      month = 12
      year = year-1
    end

  end

end




