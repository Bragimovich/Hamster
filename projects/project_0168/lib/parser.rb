require_relative '../models/us_postal_service'
require 'scylla'
require 'loofah'

class USPostalServiceParser < Hamster::Parser
  def initialize
    super
  end

  def get_news_links(pg)
    data = JSON.parse(pg)
    proceed_main_info(data)
  end

  def parse_data
    files = peon.give_list(subfolder: 'releases')
    files.each do |file|
      data_page = peon.give(subfolder: 'releases', file: file)
      link = split_link(data_page)
      news_page = split_html(data_page)
      article_info = parse_news_page(news_page)

      proceed_news = USPostalService.find_by(link: link)
      if proceed_news && proceed_news[:article].nil?
        title = article_info[0]
        article = article_info[1]
        teaser = article_info[2]
        dirty = article_info[3]
        with_table = article_info[4] == 1 ? 1 : 0
        proceed_news.update(title: title, article: article, teaser: teaser, dirty_news: dirty, with_table: with_table)
      end

      peon.move(file: file, from: 'releases', to: 'releases')
    end
    Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #168 #168 U.S. Postal Office completed successfully."
  end

  private

  def proceed_main_info(data)

    links = data.map{|i| "https://about.usps.com#{i['url']}"}
    dates = data.map{|i| i['date']}
    types = data.map{|i| i['release-type']}

    links.each_with_index do |link, i|
      date = dates[i]
      type = types[i]
      fill_main_news_data(link, date, type)
    end

    links
  end

  def parse_news_page(page)
    html = Nokogiri::HTML(page)
    title = get_title(html)
    article = get_article(html)
    teaser = get_teaser(article)
    dirty = check_dirty(article)
    with_table = 1 if article.include?("<table")
    p teaser
    [title, article, teaser, dirty, with_table]
  end

  def fill_main_news_data(link, date, type)
    begin
    h = {}
    h[:link] = link
    h[:date] = date
    h[:type] = type
    hash = USPostalService.flail { |key| [key, h[key]] }
    USPostalService.store(hash)
    rescue => e
    end
  end

  def get_title(html)
    title = html.at('#title')
    title = html.at('.headline h1') if title.nil?
    title = html.at('h1') if title.nil?

    title = title&.content&.strip.to_s.gsub("\n", ' ')
    title = cut_title(title)
    title
  end

  def cut_title(title)
   if title && title.size > 205
     title_end = title[0,201].rindex(' ')
     title = title[0, title_end] + " ..."
   end
   title
  end

  def get_article(html)
    data = html.at('.bodycontent').to_s
    if data
    end_index = data.index("###")
    article = data[0, end_index] if end_index
    end
    article
  end

  def get_teaser(article)
    if article
      data = article.split("\n")
      teaser = data.find{|i| !i.index(/bodycontent|<h1|<headline|release-date|High-resolution|<img style=|<p style=|<img src=|<img class|<p align|<p class=|resolution/) && i.size > 50}
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