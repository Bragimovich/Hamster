require_relative '../lib/message_send'
require 'scylla'

class Parser < Hamster::Parser

  def page_items(hamster, year)
    page_items = []
    items = Nokogiri::HTML.parse(hamster.body).css('#main_content ul li')
    items.each do |item|
      next if item.css('a').blank?
      link_part = item.css('a')[0][:href]
      if link_part[0] == '/'
        link = "https://www.treasurer.ca.gov#{link_part}"
      else
        link = "https://www.treasurer.ca.gov/news/releases/#{year}/#{link_part}"
      end
      next if link.include? 'index.asp'
      title = item.css('a').text.strip
      date = item
      date.css('a').remove
      date = date.text.strip
      date = date.gsub('年', '-').gsub('月', '-').gsub('日', '').strip
      date = date.blank? ? nil : Date.parse(date)
      page_items << {date: date, link: link, title: title}
    end
    page_items
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end

  def pdf(name)
    reader = PDF::Reader.new("/home/hamster/HarvestStorehouse/project_0458/trash/#{name}")
    body = reader.pages.map(&:text).join("\n")
    end_index = body.index('###')
    end_index = body.length if end_index.blank?
    body = body[0, end_index].strip
    info = ''
    if body.index('FOR IMMEDIATE RELEASE') == 0 || body.index('For Immediate Release') == 0
      body = body.split("\n")
      body = body.reject(&:blank?)
      body.shift(2)
      info = body[0]
    elsif body.index('NEWS RELEASE') == 0
      body = body.split("\n\n")
      body = body.reject(&:blank?)
      body.shift(2)
      info = body[0]
    elsif body.index('California State Treasurer') == 0
      body = body.split(/\n\n\n\n\n   |\n\n\n    |\n\n   |\n +PR/)
      body = body.reject(&:blank?)
      body.shift(3)
      info = body[0]
    end
    release_no = nil
    contact = nil
    info_arr = info.split(/    |\n/).reject(&:blank?)
    if info_arr.length == 4 && info_arr[0].include?('FOR IMMEDIATE RELEASE')
      contact = "#{info_arr[1]}, #{info_arr[3]}".strip.squeeze(' ')
    elsif info_arr.length > 4 && info_arr[0].include?('FOR IMMEDIATE RELEASE')
      info_arr_1 = info_arr[1]
      contact = info_arr.shift(3).unshift(info_arr_1).join(', ').strip.squeeze(' ')
    elsif info_arr.length == 5 && info_arr[0].include?('PR')
      release_no = info_arr[0].strip.squeeze(' ')
      contact = "#{info_arr[1]} #{info_arr[2]}, #{info_arr[4]}".strip.squeeze(' ')
    elsif info_arr.length == 4 && (info_arr[0].include?('PR') || info_arr[0].match?(/\d\d/))
      if info_arr[0].include?('PR')
        release_no = info_arr[0].strip.squeeze(' ')
      else
        release_no = "PR " + info_arr[0].strip.squeeze(' ')
      end
      contact = "#{info_arr[1]}, #{info_arr[3]}".strip.squeeze(' ')
    elsif info_arr.length == 1 && info_arr[0].include?('Contact')
      contact = "#{info_arr[0]}".strip.squeeze(' ')
    end
    body = body.join('    ').gsub(info,'')
    body = body[body.index(/ ([A-Z ]*|Sacramento) (-|–|–|–)/),body.length].strip.gsub(/\n/,' ').squeeze(' ')
    body = body.gsub('915 Capitol Mall, Room 110 | Sacramento, Calif. 95814 | p 916.653.2995 | f 916.653.3125 | www.treasurer.ca.gov','')
    { article: body, release_no: release_no, contact_info: contact }
  end

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text.strip
    data_source_url = link.gsub(/[^\/]+$/, '') + 'index.asp'
    date = date(body)
    title = title(body)
    release_no = body.css('.original_release_no').text.strip
    release_no = nil if release_no.blank?
    contact_info = body.css('.original_contact_info').text.strip
    contact_info = nil if contact_info.blank?
    article = body.css('.original_article').text.strip
    teaser = teaser(article)
    with_table = table(body)
    dirty_news = title.blank? || article.blank? || teaser.blank? || article.language != "english"
    info = {
      title: title,
      teaser: teaser,
      article: article,
      link: link,
      date: date,
      release_no: release_no,
      contact_info: contact_info,
      dirty_news: dirty_news,
      with_table: with_table,
      data_source_url: data_source_url
    }
    info
  end

  def title(body)
    title = body.css('.original_title').text.strip.gsub('​', '').gsub(' ', ' ').squeeze(' ')
    cut_title_length(title)
  end

  def cut_title_length(title)
    title = cut_title(title) if title.size > 200
    title&.sub(/:$/, '...')
  end

  def cut_title(title)
    title = title[0, 193].strip
    while title.scan(/\w{3,}$/)[0].nil?
      title = title[0, title.size - 1]
    end
    title
  end

  def teaser(article)
    teaser = article
    cut_teaser_length(teaser)
  end

  def cut_teaser_length(teaser)
    teaser = select_shortest_sentence(teaser)
    teaser = cut_sentence(teaser) if teaser.size > 600
    teaser&.sub(/:$/, '...')
  end

  def select_shortest_sentence(teaser)
    ids = []
    if teaser.size > 600
      sentence_ends = teaser.scan(/\w{3,}[.]|\w{3,}[?]|\w{3,}!/)
      sentence_ends.each do |sentence_end|
        ids << ((teaser.index sentence_end) + sentence_end.size)
      end
      teaser_new_length = ids.select { |id| id <= 600 }.max
      teaser_new_length = 600 if !teaser_new_length.nil? && teaser_new_length < 60
      teaser = teaser[0, teaser_new_length] unless teaser_new_length.nil?
    end
    teaser
  end

  def cut_sentence(teaser)
    teaser = teaser[0, 597].strip
    while teaser.scan(/\w{3,}$/)[0].nil?
      teaser = teaser[0, teaser.size - 1]
    end
    teaser
  end

  def date(body)
    date = body.css('.original_date').text.strip
    return if date.blank?
    Date.parse(date)
  end

  def table(article)
    article.include? '</table>'
  end
end

