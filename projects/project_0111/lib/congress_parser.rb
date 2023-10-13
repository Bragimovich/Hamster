# frozen_string_literal: true


def parse_main_page(html_page)
  doc = Nokogiri::HTML(html_page)
  begin
    all_page = doc.css('.pagination').css('.results-number')[0].content.split('of ')[-1].gsub(',','').to_i
  rescue =>e
    all_page = 500
  end

  basic = doc.css('.basic-search-results-lists')
  records = []
  links = []
  basic.css(".expanded").each do |row|
    records.push({})
    heading = row.css('.result-heading')[0].css('a')[0]
    #records[-1][:title] = heading.content.split(";")[0]
    #records[-1][:link] = "https://www.congress.gov" + heading['href'].split("?")[0]
    links.push("https://www.congress.gov" + heading['href'].split("?")[0])
  end
  return links, all_page
end


def parse_article_page(html_page)
  doc = Nokogiri::HTML(html_page)
  body = doc.css('.main-wrapper')[0]
  return if doc.css('h1')[0].content.match("We couldn't find that page")

  general_info = body.css('h2')[0]

  title, journal_type = general_info.to_s.split('<br>')[0].gsub("<h2>","").split(";")
  section, date = general_info.css('.quiet')[0].content.gsub(/[\(\)]/,'').split(' - ')
  featured = doc.css('.featured')
  congress_session_info = featured.css('h1')[0].css('span')[0].content

  congress_number = congress_session_info.match(/^\d*/)[0]
  congress_period = congress_session_info.match(/\d{4} - \d{4}/)[0]
  session = congress_session_info.match(/\d[a-z]{2} \w*$/)[0]

  pdf_files = []
  featured.css('.daily-digest-navigation').css('a').each do |url|
    break if url['href'].match(/^http/)
    pdf_files.push("https://www.congress.gov" + url['href'])
  end

  pdf_files_string = pdf_files.join(", ")

  if journal_type.nil?
    journal_type = doc.css('.featured').css('h1')[0].xpath('./text()')[0].content.split(' - ')[-1]
  end

  record = {
    title: title.strip.split('/')[-1].strip, journal: journal_type, section: section, date: date,
    congress_number: congress_number, congress_period: congress_period, session: session, pdf_link: pdf_files_string,
    clean_text:''
  }
  begin
    record[:text] = body.css('pre.styled')[0].content.strip #.css('.txt-box')[0]
    record[:page] = record[:text].split(/\[Pages? /)[1].split("]")[0]
  rescue => error
    p error
    p record
    # File.open("logs/proj_111", "a") do |file|
    #   file.write("#{Date.today.to_s}| #{record[:title]} | #{record[:date]} : #{error.to_s} \n")
    # end
  end

  if record[:text].nil?
    record[:dirty] = 1
  else
    text = record[:text].split('[www.gpo.gov]')[1] # delete_first_row
    text = record[:text] if text.nil?
    paragraph = "\n  "
    record[:paragraphs] = text.split(paragraph).length
    clean_text = text.gsub(/\n\n\[?.*\]\n/, ' ').gsub(/\b \n\b/, " ").gsub(/ \n\s*(?=[a-z])/, " ").gsub(/\n     (?=\w)/, " ").gsub(/(?<=.) \n\b/, " ") #for delete pagination #not check
    record[:clean_text] = clean_text.strip if !clean_text.nil?
  end


  record
end