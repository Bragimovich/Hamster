require_relative '../models/idfc'
require 'scylla'
require 'loofah'

class IDFCParser < Hamster::Parser
  def initialize
    super
  end

  def get_news_links(pg)
    html = Nokogiri::HTML(pg)
    break_condition = html.css('.grid').empty?
    return 'all pages proceed' if break_condition
    proceed_main_info(html)
  end

  def parse_data
    files = peon.give_list(subfolder: 'releases')
    files.each do |file|
      data_page = peon.give(subfolder: 'releases', file: file)
      link = split_link(data_page)
      news_page = split_html(data_page)
      article_info = parse_news_page(news_page)

      proceed_news = IDFC.find_by(link: link)
      if proceed_news && proceed_news[:article].nil?
        article = article_info[0]
        teaser = article_info[1]
        dirty = article_info[2]
        with_table = article_info[3] == 1 ? 1 : 0
        subtitle = article_info[4]
        proceed_news.update(subtitle: subtitle, article: article, teaser: teaser, dirty_news: dirty, with_table: with_table)
      end

      peon.move(file: file, from: 'releases', to: 'releases')
    end
    Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #181 International Development Finance Corporation completed successfully."
  end

  private

  def proceed_main_info(html)

      links = html.css('.grid .text a').map{|i| "https://www.dfc.gov#{i['href']}"}
      titles = html.css('.grid .text a').map{|i| i&.content&.strip}
      dates = html.css('.grid time').map{|i| i&.content}
      types = html.css('.grid .views-field-field-newsroom-type').map{|i| i&.content}

    links.each_with_index do |link, i|

      title = titles[i]
      title = cut_title(title)
      date = dates[i]
      type = types[i]
      fill_main_news_data(link, title, date, type)
    end
    links
  end

  def parse_news_page(page)
    html = Nokogiri::HTML(page)
    subtitle = html.at('.content .field--name-body h5')&.content&.strip
    article_data = html.css('.content .field--name-body')
    article = article_data.to_s
    teaser = get_teaser(article)
    dirty = check_dirty(article)
    with_table = 1 if article.include?("<table")
    [article, teaser, dirty, with_table, subtitle]
  end

  def fill_main_news_data(link, title, date, type)
    begin
    h = {}
    h[:link] = link
    h[:title] = title
    h[:date] = Date.parse(date).to_s if date
    h[:type] = type
    hash = IDFC.flail { |key| [key, h[key]] }
    IDFC.store(hash)
    rescue => e
    end
  end

  def cut_title(title)
   if title && title.size > 205
     title_end = title[0,201].rindex(' ')
     title = title[0, title_end] + " ..."
   end
   title
  end

  def get_teaser(article)
    if article
      data = article.split("\n")
      teaser = data.find{|i| !i.include?("field--type-text-with-summary") && !i.include?("<h5") && i.size > 50}
    end
    Loofah.fragment(teaser).scrub!(:strip)&.text&.strip if teaser
  end

  def check_dirty(article)
    return 1 if (article == '') || (article.language != 'english')
    0
  end

  def move_to_trash(file)
    peon.move(file: file, from: 'releases', to: 'releases')
  end

  def split_link(file_content)
    file_content.split('|||').first
  end

  def split_html(file_content)
    file_content.split('|||').last
  end
end