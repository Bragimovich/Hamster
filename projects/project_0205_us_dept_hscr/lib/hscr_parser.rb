# frozen_string_literal: true



def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  body = doc.css('.posts-listing')
  news = []

  html_list_news = body.css('article')
  html_list_news.each do |news_short|

    one_news = {}
    heading = news_short.css('.post-title')[0].css('a')[0]

    one_news[:title] = heading.content.strip
    one_news[:link] = heading['href']

    img = news_short.css('.post-image').css('img')[0]
    unless img.nil?
      one_news[:image_link] = img['src']
    else
      one_news[:image_link] = nil
    end

    one_news[:date] = Date.parse(news_short.css('.post-time')[0].content)
    one_news[:teaser] = news_short.css('.post-info')[0].content.strip
    news.push(one_news)
  end
  news
end


def parse_one_news(html, title)
  doc = Nokogiri::HTML(html)
  one_news = {}

  #one_news[:link] = doc.css('.permalink a')[0]['href']
  article = doc.css('.article-content')[0]
  one_news[:article] = article.to_s.split(title)[-1].split(/<\/h2>|<\/h1>|<\/h4>/)[-1].strip

  #one_news[:teaser] = article.css('p')[0].content.strip

  if article.css('table')[0]
    one_news[:with_table] = 1
  else
    one_news[:with_table] = 0
  end

  article.css('p').each do |paragraph|
    next if paragraph.content.match(title) || paragraph.content.length<80 || paragraph.content.match(/lick here to/)
    one_news[:teaser] = paragraph.content.strip
  end


  # if one_news[:teaser].length>800
  #   divide_str = '+++++'
  #   doc.search('br').each { |br| br.replace(divide_str) }
  #   teaser_html = doc.css('.post-content p')[0]
  #   one_news[:teaser] = teaser_html.content.split('+++++')[0]
  # elsif one_news[:teaser].length<100 || one_news[:teaser].downcase.match(/bill Text/) \
  #        || one_news[:teaser].downcase.match(/click here/) || one_news[:teaser].match(/ontact(s*):/) || one_news[:teaser].downcase.match(/for immediate release/)
  #   one_news[:teaser] = nil
  #   article.css('p').each do |p|
  #     if p.css('i') or p.css('b')
  #       next if p.content.downcase.match(/click here/) || p.content.match(/Bill Text/) || p.content.downcase.match(/for immediate release/) || p.content.match("emarks as prepared for delivery") ||  p.match(/ontact(s*):/)
  #       one_news[:teaser] = p.content
  #       break
  #     end
  #     if p.content.match('Washington,')
  #       one_news[:teaser] = p.content
  #       break
  #     end
  #
  #   end
  #
  #   teaser = nil
  #   if one_news[:teaser].nil? or one_news[:teaser].length>1000 or one_news[:teaser].length<150
  #     article.content.strip.split(/\n+/).each do |paragraph|
  #
  #       if paragraph.match(/^((Washington)|(WASHINGTON))/) || paragraph.length>150
  #         teaser = paragraph
  #         break
  #       end
  #
  #     end
  #     one_news[:teaser] = teaser
  #   end
  #
  # end
  #
  #
  # if one_news[:teaser].strip == '' || one_news[:teaser].nil?
  #   one_news[:teaser] = nil
  # else
  #   one_news[:teaser] = one_news[:teaser].strip
  # end

  if one_news[:article].match(/ que /) || one_news[:article].length<200
    one_news[:dirty_news] = 1
  else
    one_news[:dirty_news] = 0
  end


  one_news
end