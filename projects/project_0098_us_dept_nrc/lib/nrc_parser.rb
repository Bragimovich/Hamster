

def parse_list_news(html, year)
  doc = Nokogiri::HTML(html)
  news = []
  date_news = Date.new()
  table = doc.css('.table')
  rows = table.css('tr')
  rows.each do |row|
    columns = row.css('td')
    next if !columns[0]
    next if columns.length == 1

    if columns.length==3
      column_number = 1
      begin
        date_news = Date.strptime(columns[0].content, '%m/%d/%Y')
        if date_news.year!=year
          date_news = Date.new(year, date_news.month, date_news.day)
        end
      rescue
        next
      end
    else
      column_number = 0
      date_news = date_news
    end
    next if columns[column_number].css('a')[0].nil?
    release_no = columns[column_number].content.gsub(/[\*?! ]/, '').strip
    pdf_link = columns[column_number].css('a')[0]['href']
    title = columns[column_number+1].content
    news.push({
                date: date_news, release_no: release_no, link: pdf_link, title: title
              })
  end
  news
end

def raw_content_to_text(raw_content)
  raw_content.scan(/\((.*?)\)/).join('')
end


def read_pdf_file_2013_2021(file_path, realese_no, title)
  reader = PDF::Reader.new(file_path)
  paragraph_symbol = "__/P__"
  raw_content = reader.pages[0].raw_content.gsub("/P", "(#{paragraph_symbol})")
  raw_content = raw_content.gsub("\n/H1", "(__H1__)")

  all_article = raw_content_to_text(raw_content)
  #p all_article

  contact_info = reader.pages[0].text.split(/\sCONTACT[S]*:|\sContact[s]*:/)[-1].split("\n\n")[0].strip
  p all_article.split(/[\s#{paragraph_symbol}]CONTACT[S]*:|[\s#{paragraph_symbol}]Contact[s]*:/)[-1]
  article = all_article.split(/[\s#{paragraph_symbol}]CONTACT[S]*:|[\s#{paragraph_symbol}]Contact[s]*:/)[-1].split("__H1__")[-1].split(paragraph_symbol)[1..].join(paragraph_symbol).strip

  divide_by_title = all_article.split(title.split(/\s/)[-1])
  article = divide_by_title[1] if divide_by_title.length==2

  # article = text.split(contact_info)[-1].split("\n\n")[1..].join("\n\n") if article.nil?
  reader.pages[1..].each do |page|
    article+= ' ' +raw_content_to_text(page.raw_content.gsub("/P", "(#{paragraph_symbol})")).split('Page |')[0]
  end
  article = article.gsub(paragraph_symbol, "\n\n").gsub("\\222", "'").gsub("\\223", '"').gsub("\\224", '"').gsub("\\226", '–').strip
  teaser = article.split("\n\n")[0]
  p '!!!!'
  p article
  # p '__'
  # p title
  # p contact_info
  # p teaser
  contact_info = contact_info.split(/\s\s/)[0] if contact_info.length>700
  #contact_info = contact_info.split("\n")[0] if contact_info.length>700

  {contact_info: contact_info, teaser: teaser, article: article}
end





def read_pdf_file_2015(file_path, realese_no, title)
  reader = PDF::Reader.new(file_path)
  #p reader.pages[0].raw_content
  text = reader.pages[0].text
  #p text
  contact_info = ''
  if text.match(/\sCONTACT[S]*:|\sContact[s]*:/)
    contact_info += text.split(/\sCONTACT[S]*:|\sContact[s]*:/)[-1].split(title.split(' ')[0])[0].strip
  end

  # raw_content = reader.pages[0].raw_content.gsub("/P", "(__P__)")
  # text = raw_content_to_text(raw_content)

  divide_by_title = text.split(title.split(' ')[-1])
  article = divide_by_title[1..].join('') if divide_by_title.length>1
  article = text.split(contact_info)[-1].split("\n\n")[1..].join("\n\n") if article.nil? && contact_info!=''
  article = text.split("No.")[-1].split("\n\n")[1..].join("\n\n") if article.nil?
  article = article.gsub(/\n\n\s?[a-z]/, '')
  #article = article.gsub("__P__", "\n\n")


  reader.pages[1..].each do |page|
    article+= ' ' +raw_content_to_text(page.raw_content).split('Page |')[0]
  end

  article=article.split(/(###)|(# # #)/)[0].strip
  teaser = article.split("\n\n")[0].strip

  contact_info = contact_info.split("\n\n")[0] if contact_info.length>700
  # p title
  #  p contact_info
  #p teaser
  #puts
  {contact_info: contact_info.strip, teaser: teaser, article: article}
end

def read_pdf_file_2013(file_path, realese_no, title)
  reader = PDF::Reader.new(file_path)
  #p reader.pages[0].raw_content
  # text = reader.pages[0].text
  # p text
  paragraph_symbol = "__/P__"
  raw_content = reader.pages[0].raw_content.gsub("/P", "(#{paragraph_symbol})")
  raw_content = raw_content.gsub("\n/H1", "(__H1__)")
  all_article = raw_content_to_text(raw_content)
  p all_article
  article = ''
  if all_article.match("__H1__")
    article = all_article.split("__H1__")[1..].join("\n\n").split(paragraph_symbol)[1..].join("\n\n").strip
  end


  if all_article.match(/CONTACT[S]*:|Contact[s]*:/)
    contact_info = reader.pages[0].text.split(/\sCONTACT[S]*:|\sContact[s]*:/)[-1].split("\n\n")[0].strip
    article =  reader.pages[0].text.split(/\sCONTACT[S]*:|\sContact[s]*:/)[-1].split("\n\n")[2..].join("\n\n") if article.length<150
  end
  p contact_info
  p article
  teaser = article.split("\n\n")[0].strip

  puts
  puts

  # raw_content = reader.pages[0].raw_content.gsub("/P", "(__P__)")
  # text = raw_content_to_text(raw_content)
  #
  # divide_by_title = text.split(title.split(' ')[-1])
  # article = divide_by_title[1..].join('') if divide_by_title.length>1
  # article = text.split(contact_info)[-1].split("\n\n")[1..].join("\n\n") if article.nil? && contact_info!=''
  # article = text.split("No.")[-1].split("\n\n")[1..].join("\n\n") if article.nil?
  # article = article.gsub(/\n\n\s?[a-z]/, '')
  # #article = article.gsub("__P__", "\n\n")
  #
  #
  # reader.pages[1..].each do |page|
  #   article+= ' ' +raw_content_to_text(page.raw_content).split('Page |')[0]
  # end
  #
  # article=article.split(/(###)|(# # #)/)[0].strip
  #
  # p '__'
  # p title
  #  p contact_info
  #p teaser
  #puts
  {contact_info: contact_info.strip, teaser: teaser, article: article}
end



def read_pdf_file_2000_2012(file_path, year)
  dirty = 0
  article = ''
  reader = PDF::Reader.new(file_path)
  #p reader.pages[0].raw_content
  text = reader.pages[0].text
  p text
  contact_info = ''
  if text.match(/\sCONTACT[S]*:|\sContact[s]*:/)
    contact_info += text.split(/\sCONTACT[S]*:|\sContact[s]*:/)[-1].split("\n\n")[0].strip
  end

  #article = text.split(contact_info)[-1].split("\n\n")[1..].join("\n\n") if article.nil? && contact_info!=''
  article = text.split(/\sNo.?[\s\dIl:]/)[-1].split("\n\n")[1..].join("\n\n")
  divided_article = article.split(/\s+\b[A-Z0-9\-,.]+\b\s+\n/)
  if !divided_article.empty?
    if !divided_article[-1][0].match(/[a-z]/)
      article = divided_article[-1]
      # else
      #   article = divided_article[1..].join("\n")
    end
  end
  #p article
  if text.match("REGULATORY COMMISSION\n")
    contact_info += text.split("REGULATORY COMMISSION\n")[1..].join("REGULATORY COMMISSION\n").split(/\sNo.?[\s\dIl:]/)[0]
  elsif text.match("Regulatory Commission\n")
    contact_info += text.split("Regulatory Commission\n")[1..].join("Regulatory Commission\n").split(/\sNo.?[\s\dIl:]/)[0]
  elsif text.match("NRC NEWS\n")
    contact_info += text.split("NRC NEWS\n")[1].split(/\sNo.\s/)[0]
  else
    contact_info=''
  end

  contact_info = contact_info.split("#{year}\n")[0] if contact_info.length>700
  contact_info = contact_info[0..700] if contact_info.length>700
  p contact_info

  if article.nil? or article==''
    article= text.split("#{year}\n")[1..].join("\n")
    dirty = 1
  end
  p article
  reader.pages[1..].each do |page|
    break if article.match(/(###)|(# # #)/)
    article+= ' ' +page.text
  end

  article=article.split(/(###)|(# # #)/)[0].strip
  if article==''
    article= text
    dirty = 1
  end

  teaser = article.split("\n\n")[0].strip
  if teaser.length>2000
    teaser=teaset[0..2000]
    dirty=1
  end


  p '__'
  # p title
  #  p contact_info
  #p teaser
  #puts
  {contact_info: contact_info.strip, teaser: teaser, article: article, dirty: dirty}
end

def read_pdf_file_1999(file_path, realese_no, title)
  begin
    reader = PDF::Reader.new(file_path)
  rescue
    return
  end

  text = reader.pages[0].text

  if text.match("COMMISSION\n")
    contact_info = text.split("REGULATORY COMMISSION\n")[-1].split(/\sNo.?[\s\dIl:]/)[0].split("1999\n")[0]
  elsif text.match("Commission\n")
    contact_info = text.split("Regulatory Commission\n")[-1].split(/\sNo.?[\s\dIl:]/)[0].split("1999\n")[0]
  end
  p contact_info

  divided_article = text.split(/\s+\b[A-Z0-9\-,\.]+\b\s+\n/)
  article = divided_article[-1]

  reader.pages[1..].each do |page|
    break if article.match(/(###)|(# # #)/)
    article+= ' ' +page.text
  end
  article=article.split(/(###)|(# # #)/)[0].strip

  teaser = article.split("\n\n")[0].strip
  p '__'
  # p title
  #  p contact_info
  #p teaser
  #puts
  {contact_info: contact_info.strip, teaser: teaser, article: article}
end

def read_pdf_file_1998(file_path, realese_no, title)
  begin
    reader = PDF::Reader.new(file_path)
  rescue
    return
  end

  text = reader.pages[0].text

  if text.match("COMMISSION\n")
    contact_info = text.split("REGULATORY COMMISSION\n")[-1].split(/\sNo.?[\s\dIl:]/)[0].split("1998\n")[0].split("FOR")[0]
  elsif text.match("Commission\n")
    contact_info = text.split("Regulatory Commission\n")[-1].split(/\sNo.?[\s\dIl:]/)[0].split("1998\n")[0].split("FOR")[0]
  end

  divided_article = text.split(/\s+\b[A-Z0-9\-,\.]+\b\s+\n/)

  contact_info = divided_article[0].split(/COMMISSION\n|Commission\n/)[-1] if contact_info.length>700
  contact_info = contact_info[0..700] if contact_info.length>700

  article = divided_article[-1]

  reader.pages[1..].each do |page|
    break if article.match(/(###)|(# # #)/)
    article+= ' ' +page.text
  end
  article=article.split(/(###)|(# # #)/)[0].strip

  teaser = article.split("\n\n")[0].strip
  p '__'
  # p title
  #  p contact_info
  #p teaser
  #puts
  {contact_info: contact_info.strip, teaser: teaser, article: article}
end

def read_pdf_file_1996(file_path, year)
  begin
    reader = PDF::Reader.new(file_path)
  rescue
    return
  end

  text = reader.pages[0].text

  if text.match("COMMISSION\n")
    contact_info = text.split("REGULATORY COMMISSION\n")[-1].split(/\sNo.?[\s\dIl:]/)[0].split("FOR ")[0].split("#{year}\n")[0].split("FOR")[0]
  elsif text.match("Commission\n")
    contact_info = text.split("Regulatory Commission\n")[-1].split(/\sNo.?[\s\dIl:]/)[0].split("FOR ")[0].split("#{year}\n")[0].split("FOR")[0]
  end

  divided_article = text.split(/\s+\b[A-Z0-9\-,\.]+\b\s+\n/)

  contact_info = divided_article[0].split(/COMMISSION\n|Commission\n/)[-1] if contact_info.length>700
  contact_info = contact_info[0..700] if contact_info.length>700

  article = divided_article[-1]

  reader.pages[1..].each do |page|
    break if article.match(/(###)|(# # #)/)
    article+= ' ' +page.text
  end

  article=article.split(/(###)|(# # #)/)[0].strip

  teaser = article.split("\n\n")[0].strip
  p '__'
  # p title
  #  p contact_info
  #p teaser
  #puts
  {contact_info: contact_info.strip, teaser: teaser, article: article}
end

def read_html_file_2001(file_path)
  html=''
  File.open(file_path, 'r') { |file| html=file.read}
  doc = Nokogiri::HTML(html)
  dirty = 0
  contact_info = doc.xpath('//*[@id="container-wrap"]/main/div[2]/div/div/table[1]/tbody/tr/td[2]/table/tbody/tr/td/p')[0].content

  body = doc.xpath('//*[@id="container-wrap"]/main/div[2]/div/div/table[2]')
  i = 0
  text_i = 2
  article=''
  teaser=''
  begin
    body.css("tr").each do |tr|
      if tr.css('td')[0].content=="CONTACT:"
        text_i +=1
        contact_info+=tr.css('td')[1].content
        contact_info+=tr.css('td')[2].content if tr.css('td')[2]
      end
      if i==text_i
        article = tr.css('td')[0].content
        teaser = tr.css('td').css('p')[0].content
      end
      i+=1
    end
  rescue
    dirty = 1
  end
  {contact_info: contact_info, teaser: teaser, article: article, dirty:dirty }
end


def read_pdf_file_test(file_path, realese_no, title)
  reader = PDF::Reader.new(file_path)
  p reader.pages[0].raw_content
  text = reader.pages[0].text
  p text
  # contact_info = text.split(/\sCONTACT[S]*:|\sContact[s]*:/)[1].split("\n\n")[0]
  # divide_by_title = text.split(title.split(/\s/)[-1]+"\n")
  # article = divide_by_title[1] if divide_by_title.length>1
  # article = text.split(contact_info)[-1].split("\n\n")[1..].join("\n\n") if article.nil?
  # reader.pages[1..].each do |page|
  #   article+= ' ' +page.text.split('Page |')[0]
  # end
  # article=article.strip
  # teaser = article.split("\n\n")[0]
  # p '__'
  # p title
  # p teaser
  puts
end



