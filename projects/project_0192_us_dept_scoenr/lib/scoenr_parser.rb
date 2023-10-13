# frozen_string_literal: true



def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  body = doc.css('.pagegroup-content')[0]
  news = []

  html_list_news = body.css('.element')
  html_list_news.each do |news_short|

    one_news = {}
    one_news[:link] = news_short.css('a')[0]['href']
    title = news_short.css('.element-title')[0].content.strip

    one_news[:title] = title.split("\n")[0]

    one_news[:link] = one_news[:link].gsub!(' ','%20') if one_news[:link].match(' ')
    #one_news[:date] = Date.strptime(news_short.css('td')[0].content, '%m/%d/%y')
    news.push(one_news)
  end
  news
end


def parse_one_news(html)
  doc = Nokogiri::HTML(html)
  one_news = {}

  #one_news[:link] = doc.css('.permalink a')[0]['href']
  article = doc.css('.element-content')[0]
  one_news[:article] = article.to_s

  if article.css('table')[0]
    one_news[:with_table] = 1
  end

  teaser = nil
  divided_tags = ['p', 'span', 'div', 'font']
  o = 0
  while teaser.nil?
    divided_tag = divided_tags[0]
    teaser = doc.css('.element-content').css(divided_tag)[0]
    divided_tags.shift
    o +=1
    raise 'bad page' if o>4
  end
  # if teaser.nil?
  #   divided_tag='span'
  #   teaser = doc.css('.element-content').css(divided_tag)[0]
  # end

  teaser = teaser.content

  one_news[:date] = Date.parse(doc.css('.element-date')[0].content)

  if teaser.length>800
    divide_str = '+++++'
    doc.search('br').each { |br| br.replace(divide_str) }
    teaser_html = doc.css('.element-content').css(divided_tag)[0]
    teaser = teaser_html.content.split('+++++')[0]
  elsif teaser.length<100 or teaser.match(/To watch a video/) or teaser.match("ENR hearing") or teaser.match(/Click[  ]here/) or teaser.downcase.match(/for immediate release/)

    doc.css('.element-content').css(divided_tag).each do |p|
      if p.css('b') or p.css('strong')
        next if p.content.match(/To watch a video/) || p.content.match("ENR hearing") || p.content.match(/Click[  ]here/) || p.content.length<70 || p.content.downcase.match(/for immediate release/)
        teaser = p.content.strip
        break
      end
    end

  end

  if teaser.nil? or teaser.length>1000 or teaser.length<150 or teaser.match(/#*\s+#*/)
    article.content.strip.split(/\n+/).each do |paragraph|

      if paragraph.match(/^((Washington)|(WASHINGTON))/) || paragraph.downcase.match(/(u.s. sen)/) || paragraph.length>150
        teaser = paragraph.strip
        break
      end
    end
  end

  #teaser = doc.css('.element-subtitle')[0].content if teaser.length>900
  one_news[:teaser] = teaser

  one_news[:teaser] = nil if one_news[:teaser].strip == ''

  if one_news[:article].match(/ que /) || one_news[:teaser].nil? || one_news[:article].length<200
    one_news[:dirty_news] = 1
  end

  one_news
end