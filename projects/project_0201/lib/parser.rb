require_relative '../lib/message_send'
require 'scylla'

class Parser < Hamster::Parser

  def page_items(hamster)
    page = Nokogiri::HTML.parse(hamster.body)
    links = []
    items = page.css('article')
    items.each do |item|
      link = item.css('div > a')[1]['href']
      link = "https://republicans-energycommerce.house.gov#{link}"
      title = item.css('h3').text
      date = item.css('div > div > div')[7]
      date = date.blank? ? nil : date.text
      date = Date.parse(date) unless date.blank?
      logger.info "[#{links.count + 1}] #{link}"
      links << { link: link, title: title, date: date}
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    links
  end

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    title = title(body)
    date = date(body)
    subtitle = nil
    article = article(body)
    teaser = teaser(article)
    article = article.to_s.gsub(/[\u{10000}-\u{FFFFF}]/,'')
    with_table = table(article)
    dirty_news = title.blank? || article.blank? || date.blank? || teaser.blank? || article.language != "english"
    info = {
      title: title,
      subtitle: subtitle,
      date: date,
      link: link,
      teaser: teaser,
      article: article,
      with_table: with_table,
      dirty_news: dirty_news
    }
    info
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
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

  def date(body)
    date = body.css('.original_date').text.strip
    return if date.blank?
    Date.parse(date)
  end

  def article(body)
    article = body.css('main section .wysiwyg-content')
    article
  end

  def teaser(article)
    items = article.css('p')
    teaser = ''
    items.each do |item|
      teaser = item.text
      break if teaser.length >= 50
    end
    teaser = teaser.gsub(/\n|\s/,' ').squeeze(' ').strip
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

  def table(article)
    article.include? '</table>'
  end
end
