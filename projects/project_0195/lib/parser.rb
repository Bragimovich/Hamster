require_relative '../models/us_judical_conference'
require_relative '../models/us_judical_conference_tags'
require_relative '../models/us_judical_conference_tags_articles'
require 'scylla'

class USJudicalConferenceParser < Hamster::Parser
  def initialize
    super
  end

  def get_news_links(pg)
    html = Nokogiri::HTML(pg)
    return 'all pages proceed' if html.css('.news-node').empty?
    proceed_main_info(html)
  end

  def parse_data
    files = peon.give_list(subfolder: 'releases')
    files.each do |file|
      data_page = peon.give(subfolder: 'releases', file: file)
      link = split_link(data_page)
      news_page = split_html(data_page)
      article_info = parse_news_page(news_page)

      proceed_news = USJudicalConference.find_by(link: link)

      if proceed_news
        article = article_info[0]
        dirty = article_info[1]
        with_table = article_info[2] == 1 ? 1 : 0
        tags = article_info[3]
        proceed_news.update(article: article, dirty_news: dirty, with_table: with_table)

        fill_tags(tags, link)
      end

      peon.move(file: file, from: 'releases', to: 'releases')
    end
    Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #195 Judicial Conference of the United States completed successfully."
  end

  private

  def proceed_main_info(html)
    links = html.css('.news-node h2 a').map{|i| "https://www.uscourts.gov#{i['href']}"}
    titles = html.css('.news-node h2 a').map{|i| i&.content&.strip}
    dates = html.css('.news-node .date-display-single').map{|i| i&.content}
    teaseres = get_teaseres(html)

    links.each_with_index do |link, i|

      title = titles[i]
      title = cut_title(title)
      date = dates[i]
      teaser = teaseres[i]
      teaser = TeaserCorrector.new(teaser).correct if teaser
      fill_main_news_data(link, title, date, teaser)
    end
    links
  end

  def parse_news_page(page)
    html = Nokogiri::HTML(page)

    article_data = html.css('.field-name-body')
    article_data = html.css('#content') if article_data&.text == ''
    article = article_data.to_s
    dirty = check_dirty(article)
    with_table = 1 if article.include?("<table")
    tags = html.css('.label-inline + a').map{|i| i&.content}

    [article, dirty, with_table, tags]
  end

  def fill_main_news_data(link, title, date, teaser)
    h = {}
    h[:link] = link
    h[:title] = title
    h[:date] = Date.parse(date).to_s if date
    h[:teaser] = teaser
    hash = USJudicalConference.flail { |key| [key, h[key]] }
    USJudicalConference.store(hash)
  end

  def fill_tags(data, lk)
    if !data.empty?
      data.each do |d|
        h = {}
        h[:tag] = d
        hash = USJudicalConferenceTags.flail { |key| [key, h[key]] }
        USJudicalConferenceTags.store(hash)

        tag_id = USJudicalConferenceTags.find_by(tag: d)[:id]
        h_tag_link = {}
        h_tag_link[:article_link] = lk
        h_tag_link[:tag_id] = tag_id
        hash_tag_link = USJudicalConferenceTagsArticles.flail { |key| [key, h_tag_link[key]] }
        USJudicalConferenceTagsArticles.store(hash_tag_link)
      end
    end
  end

  def cut_title(title)
   if title && title.size > 205
     title_end = title[0,201].rindex(' ')
     title = title[0, title_end] + " ..."
   end
   title
  end

  def get_teaseres(html)
    teaseres = html.css('.news-node p').map{|i| i&.content&.strip}
    teaseres.delete_if {|i| !i.to_s.match(/\s/)}
    teaseres.partition.with_index{ |c, i| i.odd? }[0]
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