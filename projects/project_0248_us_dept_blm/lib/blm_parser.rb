# frozen_string_literal: true



def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  body = doc.css('.view-results')
  news = []

  html_list_news = body.css('.views-row')
  html_list_news.each do |news_short|

    one_news = {}
    heading = news_short.css('.link a')[0]

    one_news[:title] = heading.content.strip
    one_news[:link] = "https://www.blm.gov" + heading['href']

    one_news[:date] = Date.parse(news_short.css('.date')[0].content)
    news.push(one_news)
  end
  news
end


def parse_one_news(html)
  doc = Nokogiri::HTML(html)
  one_news = {}

  #one_news[:link] = doc.css('.permalink a')[0]['href']

  heading = doc.css('.topnewstext')[0]
  one_news[:contact_info] = doc.css('.press_release-contact').to_s

  organization = doc.css('.press_release-organization')[0]
  one_news[:organization] = if !organization.nil?
                         organization.content
                       else
                         nil
                       end


  article = doc.css('.press_release-body')[0]
  one_news[:article] = article.to_s

  if article.css('table')[0]
    one_news[:with_table] = 1
  else
    one_news[:with_table] = 0
  end

  teaser = article.content.strip.split("\n")[0]
  p teaser
  if teaser.nil? || teaser.length>1000 || teaser.strip =='' || teaser.length<100
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

  if teaser.nil? || teaser.length>1000 || teaser.strip =='' || teaser.length<100
    teaser = nil
    divided_tags = ['p', 'span', 'div', 'font']
    o = 0
    while teaser.nil?
      divided_tag = divided_tags[0]
      teaser = article.css(divided_tag)[0]
      divided_tags.shift
      o +=1
      raise 'bad page' if o>4
    end
    teaser = teaser.content
  end


  one_news[:teaser] = teaser

    if one_news[:article].match(/ que /) || one_news[:article].length<200 || one_news[:teaser].length<100
    one_news[:dirty_news] = 1
  else
    one_news[:dirty_news] = 0
  end

  one_news
end