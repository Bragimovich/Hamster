
#_______utils for parsing date_________
def date_format(link)
  date_str = /\/\d{4}\/\d{2}\/\d{1,2}\//.match(link).to_s[1...-1]
  Date.strptime(date_str, '%Y/%m/%d') if date_str
end

def date_from_link_2006_2012(link)
  date_str = /\/\d{8}[a-z.-]{1}/.match(link).to_s[1...-1]
  p link
  p date_str
  Date.new(date_str[0..3].to_i,date_str[4..5].to_i,date_str[6..7].to_i) if date_str
end

def date_from_link_until_2000(link)
  date_str = /\/\d{6}[a-z.-]{1}/.match(link).to_s[1...-1]
  Date.new(1900+date_str[0..1].to_i,date_str[2..3].to_i,date_str[4..5].to_i) if date_str
end

#_________END_DATE_UTILS_______________


#______PARSE 2021__________
def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('.views-element-container')[0]
  list_news_nokogiri = table.css('.news-listing-row')

  list_news_nokogiri.each do |news|
    #p news.content
    title_link = news.css('.views-field-title')[0]
    title = title_link.content

    link = title_link.css('a')[0]['href']

    additional = news.css('.date-display-single')[0]
    type = additional.content.split(' | ')[-1]
    news_short.push({:title => title, :link=>link, :date=>date_format(link),
                     :type_article=>type.downcase})
  end

  news_short
end


def parse_one_news(html)
  news_long = {}
  doc = Nokogiri::HTML(html)


  news_long[:contact_info] = doc.css('.news-release-contact-office').to_s
  full_text = doc.css('.field--name-field-uswds-body')
  news_long[:article]= full_text.to_s
  i = 0
  while not news_long[:teaser]
    paragraph = full_text.css('p')[i]
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content if em.content.length<10
    else
      news_long[:teaser] = paragraph.content
    end
    i+=1
  end
  if news_long[:teaser].match(' que ')
    news_long[:dirty]=1
  end
  news_long
end

#______END PARSE 2021__________


#______PARSE 2013-2020__________
def parse_list_news_2013_2020(html,year )
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('.view-news-releases-listing')[0]
  list_news_nokogiri = table.css('.views-row')

  list_news_nokogiri.each do |news|
    #p news.content
    title_link = news.css('.views-field-title')[0]
    title = title_link.content

    link = title_link.css('a')[0]['href']

    case year
    when 2020
      date_frm = Date.parse(news.css('.views-field')[0].css('time')[0]['datetime'])
    when (2013..2019)
      date_frm = Date.parse(news.css('.date-display-single')[0]['content'])
    end

    date_frm = date_format(link) if date_frm.nil?

    news_short.push({:title => title, :link=>link, :date=>date_frm})
  end

  news_short
end

def parse_one_news_2016_2020(html)
  news_long = {}
  doc = Nokogiri::HTML(html)


  doc.search('br').each { |br| br.replace('\n') }

  news_long[:contact_info] = doc.css('.news-release-contact-office').to_s
  full_text = doc.css('.field')
  news_long[:article]= doc.css('.field').to_s

  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }

  i = 0
  paragraph_tag = 'p'
  while not news_long[:teaser]
    paragraph = full_text.css(paragraph_tag)[i]
    if paragraph.nil?
      paragraph_tag = 'div'
      break if i>3
      i+=1
      redo
    end
    p '!'
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content if em.content.length<10 and paragraph.content.length>50
    elsif paragraph.content.length>100
      news_long[:teaser] = paragraph.content
    end
    i+=1
  end
  news_long[:teaser] = full_text.css('p')[0].content if news_long[:teaser].nil?
  if news_long[:teaser].length>2000
    news_long[:teaser] = news_long[:teaser].split("\n")[0]
  end
  news_long
end

def parse_one_news_2013_2015(html)
  news_long = {}
  doc = Nokogiri::HTML(html)


  doc.search('br').each { |br| br.replace('\n') }

  news_long[:contact_info] = doc.css('.news-release-contact-office').to_s
  full_text = doc.css('.content')
  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  news_long[:article]= full_text.to_s.split('</h1>')[1].split('###')[0]

  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }

  i = 0
  paragraph_tag = 'p'
  while not news_long[:teaser]
    paragraph = full_text.css(paragraph_tag)[i]
    p '!'
    p i
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content if em.content.length<10 and paragraph.content.length>50
      p 'em'
    elsif paragraph.content.length>100
      p 'q'
      news_long[:teaser] = paragraph.content
    end
    i+=1
  end
  if news_long[:teaser].length>2000
    news_long[:teaser] = news_long[:teaser].split("\n")[0]
  end
  news_long
end


#_______END PARSE 2013-2020__________



#_______PARSE 2012_____

def parse_list_news_2012(html)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('[id="main-content"]')[0]

  list_news_nokogiri = table.css('.lead_snippet')

  list_news_nokogiri.each do |news|
    #p news.content
    title_link = news.css('a')[0]
    title = title_link.content.strip

    link = title_link['href']

    date_frm = date_from_link_2006_2012(link)
    news_short.push({:title => title, :link=>link, :date=>date_frm})
  end

  news_short
end

def parse_one_news_2012(html)
  news_long = {}
  doc = Nokogiri::HTML(html)


  doc.search('br').each { |br| br.replace('\n') }

  news_long[:contact_info] = doc.css('[id="prContactInfo"]').to_s
  full_text = doc.css('[id="main-content"]')
  news_long[:article]= full_text.to_s.split('</h3>')[1].split('###')[0]

  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }
  p full_text.to_s
  i = 0
  paragraph_tag = 'p'
  while not news_long[:teaser]
    paragraph = full_text.css(paragraph_tag)[i]
    p '!'
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content if em.content.length<10 and paragraph.content.length>50
      p 'em'
    elsif paragraph.content.length>100
      p 'q'
      news_long[:teaser] = paragraph.content
    end
    i+=1
  end
  if news_long[:teaser].length>2000
    news_long[:teaser] = news_long[:teaser].split("\\n")[0]
  end
  news_long
end

#_______END  PARSE 2012_____




def parse_list_news_2011(html)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('.content')[0]

  list_news_nokogiri = table.css('.hhs_inlineVariant')

  list_news_nokogiri.each do |news|
    #p news.content
    title_link = news.css('a')[0]
    title = title_link.content.strip

    link = title_link['href']
    date_frm = date_from_link_2006_2012(link)
    news_short.push({:title => title, :link=>link, :date=>date_frm})
    p news_short[-1]
  end

  news_short
end

def parse_list_news_2009_2010(html)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('.content')[0]

  list_news_nokogiri = table.css('.rxlink')

  list_news_nokogiri.each do |news|
    #p news.content
    title = news.content.strip

    link = news['href']
    date_frm = date_from_link_2006_2012(link)
    news_short.push({:title => title, :link=>link, :date=>date_frm})
    p news_short[-1]
  end

  news_short
end


def parse_list_news_2006_2008(html)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('.main_content')[0]

  list_news_nokogiri = table.css('.rxlink')

  list_news_nokogiri.each do |news|
    #p news.content
    title = news.content.strip

    link = news['href']
    next if link==''
    date_frm = date_from_link_2006_2012(link)
    news_short.push({:title => title, :link=>link, :date=>date_frm})
    p news_short[-1]
  end

  news_short
end

def parse_list_news_2005(html)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.xpath('/html/body/table[3]')
  #p table.to_s
  list_news_nokogiri = table.css('li')

  list_news_nokogiri.each do |news|
    title = news.content.strip.encode('UTF-8', :invalid => :replace).split("\n")[-1].strip

    link = news.css('a')[0]['href']
    next if link==''
    date_frm = date_from_link_2006_2012(link)
    date_frm = Date.new(year,1,1) if date_frm.nil?
    news_short.push({:title => title, :link=>link, :date=>date_frm})
  end

  news_short
end


def parse_list_news_2002_2005(html, year)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('body').css('table')[1]
  #p table.to_s
  list_news_nokogiri = table.css('li')

  list_news_nokogiri.each do |news|
    title = news.content.strip.encode('UTF-8', :invalid => :replace).split("\n")[-1].strip

    link = news.css('a')[0]['href']
    next if link==''
    date_frm = date_from_link_2006_2012(link)
    date_frm = Date.new(year,1,1) if date_frm.nil?
    news_short.push({:title => title, :link=>link, :date=>date_frm})
    p news_short[-1]
  end

  news_short
end


def parse_list_news_2002(html, year)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('body').css('table')[1]
  #p table.to_s
  list_news_nokogiri = table.css('li')

  list_news_nokogiri.each do |news|
    title = news.css('a')[0].content.encode('UTF-8', :invalid => :replace).gsub(/\s*\n\s*/, ' ')
    link = news.css('a')[0]['href']
    next if link==''
    date_frm = date_from_link_2006_2012(link)
    date_frm = Date.new(year,1,1) if date_frm.nil?
    news_short.push({:title => title, :link=>link, :date=>date_frm})
    p news_short[-1]
  end

  news_short
end




def parse_one_news_2009_2011(html)
  news_long = {}
  doc = Nokogiri::HTML(html)


  doc.search('br').each { |br| br.replace('\n') }


  full_text = doc.css('.content')
  news_long[:contact_info] = full_text.css('table').css('td')[1].css('p').to_s
  full_text.search('table').each { |table| table.replace("") }
  if full_text.css('h3').length<2
    news_long[:article]= full_text.to_s.split('</h3>')[-1].split('###')[0]
    news_long[:dirty] = 0
  elsif full_text.css('h1').length<2
    news_long[:article]= full_text.to_s.split('</h1>')[-1].split('###')[0]
    news_long[:dirty] = 1
  else
    news_long[:article]= full_text.to_s.split('###')[0]
    news_long[:dirty] = 1
  end

  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }

  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }
  i = 0
  paragraph_tag = 'p'
  while not news_long[:teaser]
    paragraph = full_text.css(paragraph_tag)[i]
    p '!'
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content.strip if em.content.length<10 and paragraph.content.length>50
      p 'em'
    elsif paragraph.content.length>100
      p 'q'
      news_long[:teaser] = paragraph.content.strip
    end
    i+=1
  end
  news_long[:teaser] = news_long[:teaser].split("\\n")[0].strip if news_long[:teaser].length>2000
  news_long
end


def parse_one_news_2006_2008(html)
  news_long = {}
  doc = Nokogiri::HTML(html)


  doc.search('br').each { |br| br.replace('\n') }


  full_text = doc.css('.main_content')
  news_long[:contact_info] = full_text.css('table').css('td')[1].css('p').to_s

  if full_text.css('h3').length<2
    news_long[:article]= full_text.to_s.split('</h3>')[-1].split('###')[0]
    news_long[:dirty] = 0
  elsif full_text.css('h1').length<2
    news_long[:article]= full_text.to_s.split('</h1>')[-1].split('###')[0]
    news_long[:dirty] = 1
  else
    news_long[:article]= full_text.to_s.split('###')[0]
    news_long[:dirty] = 1
  end

  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }
  i = 0
  paragraph_tag = 'p'
  while not news_long[:teaser]
    paragraph = full_text.css(paragraph_tag)[i]
    p '!'
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content if em.content.length<10 and paragraph.content.length>50
      p 'em'
    elsif paragraph.content.length>100
      p 'q'
      news_long[:teaser] = paragraph.content
    end
    i+=1
  end
  news_long[:teaser] = news_long[:teaser].split("\\n")[0] if news_long[:teaser].length>2000
  news_long
end

def parse_one_news_2003_2005(html)
  news_long = {}
  doc = Nokogiri::HTML(html.force_encoding("UTF-8").encode('UTF-8', :invalid => :replace))

  doc.search('br').each { |br| br.replace('\n') }

  full_text = doc.css('table[@id="skip"]')[0]
  news_long[:contact_info] = full_text.css('table').css('td')[1].css('p').to_s.encode('UTF-8', :invalid => :replace)

  if full_text.css('h3').length<2
    news_long[:article]= full_text.to_s.encode('UTF-8', :invalid => :replace).split('</h3>')[-1].split('###')[0]
    news_long[:dirty] = 0
  elsif full_text.css('h1').length<2
    news_long[:article]= full_text.to_s.encode('UTF-8', :invalid => :replace).split('</h1>')[-1].split('###')[0]
    news_long[:dirty] = 1
  else
    news_long[:article]= full_text.to_s.encode('UTF-8', :invalid => :replace).split('###')[0]
    news_long[:dirty] = 1
  end
  full_text = Nokogiri::HTML(news_long[:article])

  full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }
  i = 0
  paragraph_tag = 'p'
  while not news_long[:teaser]
    paragraph = full_text.css(paragraph_tag)[i]
    p '!'
    em = paragraph.css('em')[0]
    if em
      news_long[:teaser] = paragraph.content.encode('UTF-8', :invalid => :replace) if em.content.length<10 and paragraph.content.length>50
      p 'em'
    elsif paragraph.content.length>100
      p 'q'
      news_long[:teaser] = paragraph.content.encode('UTF-8', :invalid => :replace)
    end
    i+=1
  end
  news_long[:teaser] = news_long[:teaser].split("\\n")[0] if news_long[:teaser].length>2000
  news_long
end


#________UNTIL 2001_________

def parse_list_news_2001(html, year)
  doc = Nokogiri::HTML(html)
  news_short = []

  table = doc.css('body')
  list_news_nokogiri = table.css('li')

  list_news_nokogiri.each do |news|
    title = news.content.encode('UTF-8', :invalid => :replace).split('--')[-1].strip

    link = news.css('a')[0]['href'] if news.css('a')[0]
    next if link==''
    begin
      date_frm = date_from_link_until_2000(link) if year<2000
      date_frm = date_from_link_2006_2012(link) if year>1999 || date_frm.nil?
    rescue
      date_frm = Date.new(year,1,1)
    end
    date_frm = Date.new(year,1,1) if !date_frm
    news_short.push({:title => title, :link=>link, :date=>date_frm})
    #p news_short[-1]
  end

  news_short
end

def parse_one_news_1999_2002(html)
  news_long = {}
  doc = Nokogiri::HTML(html.force_encoding("UTF-8"))

  #doc.search('br').each { |br| br.replace('\n') }


  full_text = doc.css('body')[0]
  full_text.search('div[@class="footer"]').each { |footer| footer.replace('\n') }
  news_long[:contact_info] = full_text.xpath('/html/body/table[2]/tbody/tr/td[3]').to_s.encode('UTF-8', :invalid => :replace)
  p full_text.to_s
  begin
    news_long[:article]= full_text.to_s.encode('UTF-8', :invalid => :replace).split('<!--TEXT OF RELEASE-->')[1].split('<!--FOOTER-->')[0]
  rescue
    news_long[:article]= full_text.to_s.encode('UTF-8', :invalid => :replace).split('<hr>')[1].split("###")[0]
  end
  p news_long
  #full_text.search('li').each { |li| li.replace("<p>#{li.content}</p>") }
  #full_text.search('ul').each { |li| li.replace("<p>#{li.content}</p>") }
  # i = 0
  # paragraph_tag = 'p'
  # while not news_long[:teaser]
  #   paragraph = full_text.css(paragraph_tag)[i]
  #   p '!'
  #   em = paragraph.css('em')[0]
  #   if em
  #     news_long[:teaser] = paragraph.content.encode('UTF-8', :invalid => :replace) if em.content.length<10 and paragraph.content.length>50
  #     p 'em'
  #   elsif paragraph.content.length>100
  #     p 'q'
  #     news_long[:teaser] = paragraph.content.encode('UTF-8', :invalid => :replace)
  #   end
  #   i+=1
  # end
  if news_long[:article]
    doc = Nokogiri::HTML(news_long[:article])
    if doc.css('p')[0]
      news_long[:teaser] = doc.css('p')[0].content
      news_long[:teaser] = doc.css('p')[1].content if news_long[:teaser].length<100
    end
    news_long[:teaser] = news_long[:teaser].split("\\n")[0] if news_long[:teaser].length>2000
    news_long[:teaser] = news_long[:teaser][0..1999] if news_long[:teaser].length>2000
  end
  news_long
end



def parse_one_news_1995_1998(html, year)
  news_long = {}
  doc = Nokogiri::HTML(html.force_encoding("UTF-8"))

  doc.search('br').each { |br| br.replace('\n') }

  full_text = doc.css('body')[0]
  full_text.search('div[@class="footer"]').each { |footer| footer.replace('\n') }

  news_long[:contact_info] = full_text.xpath('/html/body/pre').to_s.encode('UTF-8', :invalid => :replace)
  news_long[:contact_info] = '' if news_long[:contact_info].length>650

  begin
    news_long[:article] = full_text.to_s.encode('UTF-8', :invalid => :replace).split("The links are no longer being updated.")[-1].split('# # #')[0].split('###')[0].strip
  rescue
    news_long[:article] = full_text.to_s.encode('UTF-8', :invalid => :replace)
  end


  news_long[:teaser] = news_long[:article].split('<p>')[0]
  if news_long[:teaser].nil?
    news_long[:teaser] = news_long[:article].split('<p>')[1].split('</p>')[0]
  elsif news_long[:teaser].length<100
    news_long[:teaser] = news_long[:article].split('<p>')[1].split('</p>')[0]
  end

  news_long[:teaser] = news_long[:teaser].split("\\n")[0] if news_long[:teaser].length>2000
  news_long[:teaser] = news_long[:teaser][0..2000] if news_long[:teaser].length>2000
  news_long[:teaser] = Nokogiri::HTML(news_long[:teaser]).content

  news_long
end


def parse_one_news_1991_1994(txt_file,year)
  news_long = {}
  txt_file=txt_file.force_encoding('ISO-8859-1').split("The links are no longer being updated.")[-1].strip
  general_text = []

  general_text_splited = txt_file.split(/\sContact[s]*:/)
  p general_text_splited.length
  if general_text_splited.length>1
    if general_text_splited[1].length>general_text_splited[0].length
      general_text_splited = general_text_splited[1].split(/\s{2,}/)
      general_text = [general_text_splited[0], general_text_splited[1..].join("\n\n")]
    else
      general_text = [general_text_splited[1], general_text_splited[0]]
    end
  else
    general_text = ['', general_text_splited[0]]
  end

  p general_text
  p txt_file
  if general_text.length<2 && !general_text[0].nil?
    general_text = general_text[0].strip.split("\n")
    general_text[1] = general_text[1..].join("\n")
  elsif general_text[0].nil?
    general_text = ['', txt_file]
  end
  news_long[:contact_info] = general_text[0].strip.encode('UTF-8', :invalid => :replace)
  news_long[:article]= general_text[1].split('###')[0].split('# # #')[0].strip.encode('UTF-8', :invalid => :replace)
  news_long[:teaser] = news_long[:article].split("\n\n")[0]
  p "Teaser:::: #{news_long[:teaser]}"
  news_long
end