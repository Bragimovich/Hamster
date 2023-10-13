# frozen_string_literal: true



def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  news = []

  html_list_news = doc.css('.l-view__content').css('.l-view__row')
  html_list_news.each do |news_short|

    one_news = {}
    heading = news_short.css('.teaser__heading')[0].css('a')[0]

    one_news[:title] = heading.content.strip
    one_news[:link] = "https://www.dea.gov" + heading['href']

    one_news[:teaser] = news_short.css('.teaser__text')[0].content.strip
    one_news[:date] = Date.parse(news_short.css('.teaser__date')[0].content)
    news.push(one_news)
  end
  news
end


def parse_one_news(html)
  doc = Nokogiri::HTML(html)
  one_news = {}

  one_news[:contact_info] = doc.css('.press__contact')[0].to_s
  article = doc.css('.wysiwyg')[0]
  one_news[:article] = article.to_s

  if article.css('table')[0]
    one_news[:with_table] = 1
  end
  if one_news[:article].match(/ que /)
    one_news[:dirty_news] = 1
  end


  one_news[:tags] = []
  doc.css('.button--tag').each do |tag|
    one_news[:tags].push(tag.content.strip)
  end
  one_news
end