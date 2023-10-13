# frozen_string_literal: true



def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  body = doc.css('.UnorderedNewsList')
  news = []

  html_list_news = body.css('li')
  html_list_news.each do |news_short|

    one_news = {}
    heading = news_short.css('a')[0]

    one_news[:title] = heading.content.strip
    one_news[:link] = "https://republicans-transportation.house.gov/news/" + heading['href']

    date = news_short.content.split('Posted in Press Releases on')[-1].split('|')[0]
    one_news[:date] = Date.parse(date)
    news.push(one_news)
  end
  news
end


def parse_one_news(html)
  doc = Nokogiri::HTML(html)
  one_news = {}

  #one_news[:link] = doc.css('.permalink a')[0]['href']

  heading = doc.css('.topnewstext')[0]
  one_news[:contact_info] = heading.to_s.split('</b>')[-1].split('<span ')[0].strip

  date = heading.css('b')[0].content.split('')

  categories = []
  doc.css('[@id=ctl00_ctl26_CatTags]').css('a').each do |tag|
    categories.push(tag.content.strip)
  end
  one_news[:categories] = categories
  article = doc.css('.bodycopy')[0]
  one_news[:article] = article.to_s

  if article.css('table')[0]
    one_news[:with_table] = 1
  else
    one_news[:with_table] = 0
  end

  teaser = article.content.strip.split("\n")[0]
  p teaser
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