# frozen_string_literal: true

require 'yaml'
require_relative '../models/ne_invest_finance_authority'
require_relative '../models/ne_invest_finance_authority_categories'
require_relative '../models/ne_invest_finance_authority_categories_article_links'
require_relative '../models/ne_invest_finance_authority_runs'

class NIFAScraper < Hamster::Scraper
  SOURCE = 'https://www.nifa.org'
  SUB_PATH = '/news'
  SUB_FOLDER = 'ne_invest_finance_authority/'
  DAY = 86400
  TEN_MINUTES = 600
  FIVE_MINUTES = 300

  def initialize
    @all_articles = []
    @i = 0
    super
  end

  def start_download
    loop do
      begin
        download
        p 'went to sleep'
        sleep(DAY)
      rescue => e
        p 'inside rescue'
        p e
        p e.backtrace
        Hamster.report(to: 'sam.putz', message: "Project # 0183 --download: Error - \n#{e}, went to sleep for 10 min", use: :both)
        sleep(TEN_MINUTES)
      end
    end
  end

  def start_store
    parser = NIFAParser.new
    loop do
      begin
        store(parser)
        p 'went to sleep'
        sleep(DAY)
      rescue => e
        p 'inside rescue'
        p e
        p e.backtrace
        Hamster.report(to: 'sam.putz', message: "Project # 0183 --store: Error - \n#{e}, went to sleep for 10 min", use: :both)
        sleep(TEN_MINUTES)
      end
    end
  end

  private

  def download
    parser = NIFAParser.new

    mark_as_started
    filter     = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    main_page  = get_main_page(filter)
    page_links = get_page_links(main_page, filter, parser)
    @all_dates = []

    page_links.each do |page_link|
      begin
        links  = get_links(page_link, filter, parser)
        save_pages(links, filter)
      rescue StandardError => e
        p e
        p e.full_message
        Hamster.report(to: 'sam.putz', message: "Project # 0183 --download: Error - \n#{e}, went to sleep for 5 min", use: :both)
        sleep(FIVE_MINUTES)
      end
    end
    write_to_yaml
    mark_as_finished
  end

  def store(parser)
    mark_store_as_started
    process_current_pages(parser)
    mark_store_as_finished
    # files_to_trash
  end
  
  def process_current_pages(parser)
    last_run = NIFARuns.last
    @run_id = last_run.id
    process_each_file(parser)
  end

  def process_each_file(parser)
    begin
      files = peon.give_list(subfolder: SUB_FOLDER)

      loop do
        break if files.empty?
        file = files.pop
        file_content = peon.give(subfolder: SUB_FOLDER, file: file)
        result = parser.parse(file_content, file, @run_id)
        next if result.nil?
        store_row(result)
      end
    rescue => e
      p e
      p e.backtrace
      Hamster.report(to: 'sam.putz', message: "Project # 0183 --store: Error - \n#{e}, went to sleep for 5 min", use: :both)
      sleep(FIVE_MINUTES)
    end
  end

  def store_row(row)
    run_id,title,teaser,article,link,creator,type,country,date,contact_info,dirty_news,
    with_table,scrape_frequency,data_source_url,category = row
    ne_invest_finance_authority = NIFAuthority.new
    ne_invest_finance_authority_categories_article_links = NIFACategoriesArticleLinks.new

    ne_invest_finance_authority.run_id    = run_id
    ne_invest_finance_authority.title     = title
    ne_invest_finance_authority.teaser    = teaser
    ne_invest_finance_authority.article   = article
    ne_invest_finance_authority.link      = link
    ne_invest_finance_authority.creator   = creator
    ne_invest_finance_authority.type      = type
    ne_invest_finance_authority.country   = country
    ne_invest_finance_authority.date      = date
    ne_invest_finance_authority.contact_info  = contact_info
    ne_invest_finance_authority.dirty_news    = dirty_news
    ne_invest_finance_authority.with_table    = with_table
    ne_invest_finance_authority.scrape_frequency = scrape_frequency
    ne_invest_finance_authority.data_source_url  = data_source_url

    ne_invest_finance_authority.save if NIFAuthority.find_by(link: ne_invest_finance_authority.link).nil?

    ne_invest_finance_authority_categories_article_links.article_link = ne_invest_finance_authority.link
    ne_invest_finance_authority_categories_article_links.prlog_category_id = NIFACategories.find_by(category: category).id unless NIFACategories.find_by(category: category).nil?
    ne_invest_finance_authority_categories_article_links.save if NIFACategoriesArticleLinks.find_by(article_link: ne_invest_finance_authority.link).nil?
  end

  def add_to_all_links(rows)
    rows.each do |r|
      @all_articles.push(r)
    end
  end
  
  def strip_trailing_spaces(text)
    text.strip.reverse.strip.reverse
  end
  
  def mark_store_as_started
    last_run = NIFARuns.last
    NIFARuns.find(last_run.id).update(status: 'store started')
  end

  def mark_store_as_finished
    last_run = NIFARuns.last
    NIFARuns.find(last_run.id).update(status: 'store finished')
  end

  def mark_as_started
    NIFARuns.create
    last_run = NIFARuns.last
    NIFARuns.find(last_run.id).update(status: 'download started')
  end
  
  def mark_as_finished
    last_run = NIFARuns.last
    NIFARuns.find(last_run.id).update(status: 'download finished')
  end
  
  def get_main_page(filter)
    connect_to(SOURCE + SUB_PATH, proxy_filter: filter)&.body
  end
  
  def get_page_links(main_page, filter, parser)
    page_links, next_page_url_num = parser.parse_page_links(main_page)
    loop do
      next_page_raw = connect_to("https://www.nifa.org/news?os=#{next_page_url_num}", proxy_filter: filter)&.body
      next_page     = parser.parse_next_page(next_page_raw)
      page_url      = "https://www.nifa.org/news?os=#{next_page_url_num}"
      page_links << page_url
      break if parser.break_if_next_page(next_page) == false
      next_page_url_num = parser.get_next_page_url_num(next_page)
    end
    page_links
  end
  
  def get_links(l, filter, parser)
    page = connect_to(l, proxy_filter: filter)&.body
    articles, article_links = parser.parse_page_of_articles(page, @all_dates)

    article_links.each do |article_link, date|

      article_page_unparsed = connect_to(article_link, proxy_filter: filter)&.body
      headline = parser.parse_article_page(article_page_unparsed)
      article_hash = {
        article_link.split("/").last => [
          article_link,
          headline,
          date
        ]
      }
      add_to_all_links(article_hash)
    end
    articles
  end

  def write_to_yaml
    Dir.mkdir("#{ENV['HOME']}/HarvestStorehouse/project_0183/store/yaml") unless File.exists?(
        "#{ENV['HOME']}/HarvestStorehouse/project_0183/store/yaml"
    )
    yaml_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0183/store/yaml/rows.yml"
    
    File.write(yaml_storage_path, @all_articles.to_yaml)
  end

  def save_pages(links, filter)
    links.each do |l|
      new_link = NIFAuthority.find_by(link: l).nil?
      next unless new_link
      begin
        page = connect_to(l , proxy_filter: filter)&.body
        save_file(page, l)
      rescue StandardError => e
        p e
        p e.full_message
      end
    end
  end

  def save_file(html, l)
    name = l.split('/').last
    peon.put content: html, file: "#{name}", subfolder: SUB_FOLDER
  end

  def files_to_trash
    trash_folder = SUB_FOLDER
    peon.list.each do |zip|
      peon.give_list(subfolder: zip).each do |file|
        peon.move(file: file, from: zip, to: trash_folder)
      end
    end
  end
  
  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end

    response
  end

end
