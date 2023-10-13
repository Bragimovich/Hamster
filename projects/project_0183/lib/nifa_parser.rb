# frozen_string_literal: true
# 
require 'yaml'
require_relative '../models/ne_invest_finance_authority'
require_relative '../models/ne_invest_finance_authority_categories'
require_relative '../models/ne_invest_finance_authority_categories_article_links'
require_relative '../models/ne_invest_finance_authority_runs'

class NIFAParser < Hamster::Parser
  SOURCE = 'https://www.nifa.org'
  SUB_PATH = '/news'
  SUB_FOLDER = 'ne_invest_finance_authority/'
  DAY = 86400
  TEN_MINUTES = 600
  FIVE_MINUTES = 300

  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
    # Here you see the convenience of monkeypatching... sometimes.
  end

  def strip_trailing_spaces(text)
    text.strip.reverse.strip.reverse
  end

  def get_next_page_url_num(next_page)
    next_page.css('span.next.control').css('a')[0]['href'].gsub(/.+?os=(\d+)$/, '\1').to_s
  end

  def break_if_next_page(next_page)
    next_page.css('span.cur.last').text.empty?
  end

  def parse_next_page(next_page_raw)
    Nokogiri::HTML(next_page_raw)
  end

  def parse_page_links(main_page)
    document   = Nokogiri::HTML(main_page)
    page_links = ["https://www.nifa.org/news?os=0"]
    next_page_url_num = document.css('span.next.control').css('a')[0]['href'].gsub(/.+?os=(\d+)$/, '\1').to_s
    [page_links, next_page_url_num]
  end

  def parse_article_page(article_page_unparsed)
    article_page = Nokogiri::HTML(article_page_unparsed)
    news_content = article_page.css('div.news_article')
    headline = news_content.css('h1').children.text
    headline
  end

  def parse_page_of_articles(page, all_dates)
    @all_dates = all_dates
    page_of_articles = Nokogiri::HTML(page)
    @month = Date.today.month unless @month
    @year = Date.today.year unless @year
    dates = page_of_articles.css('p.date').text.gsub(/(\d+)/, '\1,').split(",").map do |date| 
      date = Date.strptime(date.concat(" #{@year}"), '%b %d %Y').to_s
      @all_dates << date if @all_dates.empty?
      @month = Date.parse(date).month 
      if Date.parse(@all_dates.last).month < Date.parse(date).month
        @year = @year - 1
        date = Date.parse(date).prev_year.to_s
      end
      @all_dates << date
      Date.parse(date).prev_day.to_s
    end
    articles = page_of_articles.css('div.article-teaser').css('a').map {|el| SOURCE + el['href'] }
    article_links = articles.zip(dates)
    [articles, article_links]
  end

  def parse(file_content, file, run_id)
    begin
    @run_id = run_id
    file_name = file.gsub('.gz', '')
    p file_name

    article_doc = Nokogiri::HTML(file_content).at('.news_content')
    article_doc.search('h1').children.remove
    article_doc.search('h1').remove
    if article_doc.search('h2').first.nil? == false || article_doc.search('h3').first.nil? == false
      article_doc.search('h2').first.nil? ?  article_doc.search('h3').first.remove : article_doc.search('h2').first.remove
    end

    article_doc.css('div').find_all {|div| all_children_are_blank?(div)}.each {|div| div.remove }

    article = article_doc.children.to_html.strip

    teaser_doc = Nokogiri::HTML(file_content).at('.news_article')
    teaser_doc.search('h1').children.remove
    teaser_doc.search('h1').remove

    contact_info = Nokogiri::HTML(file_content).css('p.phone').map{|el| el.css('a').first['href']}
    contact_info += Nokogiri::HTML(file_content).search('div.menu.social-media-links').css('a').map {|el| el['href']}
    contact_info = contact_info.to_json

    begin
      if teaser_doc.search('h2').first.nil? == false || teaser_doc.search('h3').first.nil? == false
        teaser = teaser_doc.search('h2').first.nil? ?  teaser_doc.search('h3').first.text.strip : teaser_doc.search('h2').first.text.strip
        teaser_doc = teaser_doc.at('.news_content')
        if teaser.gsub(/[[:space:]]/, '') == '' && teaser_doc.search('p')[0].nil? == false
          teaser = teaser_doc.search('p')[0].text.strip
          if teaser.gsub(/[[:space:]]/, '') == '' && teaser_doc.search('p')[1].nil? == false
            teaser = teaser_doc.search('p')[1].text.strip
          end
        end
      elsif teaser_doc.search('h2').first.nil? && teaser_doc.search('h3').first.nil? && teaser_doc.at('.news_content').search('p')[0].nil? == false
        teaser_doc = teaser_doc.at('.news_content')
        teaser = teaser_doc.search('p')[0].text.strip
        if teaser.gsub(/[[:space:]]/, '') == '' && teaser_doc.search('p')[1].nil? == false
          teaser = teaser_doc.search('p')[1].text.strip
        end
      else
        teaser = article.strip
      end
      # teaser = strip_trailing_spaces(news_content.css('p').first.text).gsub(/\n+/, " ")
      teaser = TeaserCorrector.new(teaser).correct
      
    rescue => e
      p e
      p e.backtrace
      p file_name
      p 'first'
      Hamster.report(to: 'sam.putz', message: "Project # 0183 --store: Error - \n#{e}, went to sleep for 10 min", use: :both)
      sleep(TEN_MINUTES)
    end

    yaml_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0183/store/yaml/rows.yml"
    additional_info = YAML.load(File.read(yaml_storage_path)).group_by{|el| el[0]}
    additional_info = additional_info.each {|key,val| additional_info[key] = val[0][1]}

    run_id    = @run_id
    title     = additional_info[file_name][1]
    teaser    = teaser
    article   = strip_trailing_spaces(article)
    link      = additional_info[file_name][0]
    creator   = 'Nebraska Investment Finance Authority'
    type      = 'press release'
    country   = 'US'
    date      = additional_info[file_name][2]
    contact_info  = contact_info
    dirty_news    = strip_trailing_spaces(Nokogiri::HTML(article).text) == "" ? 1 : 0
    with_table    = Nokogiri::HTML(article).css('table').empty? ? 0 : 1
    scrape_frequency = 'daily'
    data_source_url  = 'https://www.nifa.org/news'
    category  = Nokogiri::HTML(file_content).css('p.news_categories').map(&:text).first.strip.gsub(/\s\s+/, ",").split(",").last
    
    [run_id,
        title,
        teaser,
        article,
        link,
        creator,
        type,
        country,
        date,
        contact_info,
        dirty_news,
        with_table,
        scrape_frequency,
        data_source_url,
        category]
    rescue => e
      p e
      p e.backtrace
      p file
      p 'last'
      Hamster.report(to: 'sam.putz', message: "Project # 0183 --store: Error - \n#{e} \n#{file}, went to sleep for 10 min", use: :both)
      sleep(TEN_MINUTES)
    end
  end

end
