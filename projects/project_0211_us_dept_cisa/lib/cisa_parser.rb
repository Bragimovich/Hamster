# frozen_string_literal: true



def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  body = doc.css('table').css('tbody')
  news = []
  html_list_news = body.css('tr')
  html_list_news.each do |news_short|
    one_news = {}
    heading = news_short.css('td')[1].css('a')[0]

    one_news[:title] = heading.content.strip
    one_news[:link] = "https://www.cisa.gov" + heading['href']

    date = news_short.css('td')[0].content
    one_news[:date] = Date.parse(date)

    news.push(one_news)
  end
  news
end


def parse_one_news(html)
  doc = Nokogiri::HTML(html)
  one_news = {}

  #one_news[:link] = doc.css('.permalink a')[0]['href']


  categories = []
  doc.css('.field--name-field-taxonomy-topics .field--items').css('a').each do |category|
    categories.push(category.content.strip)
  end
  one_news[:categories] = categories

  tags = []
  doc.css('.field--name-field-keywords .field--items').css('a').each do |tag|
    tags.push(tag.content.strip)
  end
  one_news[:tags] = tags


  article = doc.css('article')[0]

  one_news[:article] = article.to_s

  if article.css('table')[0]
    one_news[:with_table] = 1
  else
    one_news[:with_table] = 0
  end

  teaser = article.content.strip.split("\n")[0]

  one_news[:teaser] = if teaser.nil? || teaser.length>1000 || teaser.strip =='' || teaser.length<100
                        divide_str = '+++++'
                        article.search('br').each { |br| br.replace(divide_str) }
                        article.css('p').each do |p|
                          if p.content.length>100
                            teaser = p.content.split('+++++')[0].strip
                            break
                          end
                        end
                        teaser
                      else
                        teaser.strip
                      end

  if one_news[:article].match(/ que /) || one_news[:article].length<200 || one_news[:teaser].length<100
    one_news[:dirty_news] = 1
  else
    one_news[:dirty_news] = 0
  end

  one_news
end