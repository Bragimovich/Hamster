require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_items(hamster)
    page = Nokogiri::HTML.parse(hamster.body)
    links = []
    items = page.css('.collection-results .collection-result')
    items.each do |item|
      type = item.css('.collection-result__date').text
      type = type.blank? ? nil : type.strip.downcase
      title = item.css('.collection-result__link').text.strip
      link = item.css('.collection-result__link')[0]['href']
      next if link.include? 'https://www.state.gov/religiousfreedom/'
      date = nil
      dates_span = item.css('.collection-result-meta span')
      dates_span.each do
        date = if dates_span.count > 1
                 dates_span[1].text.to_s
               elsif dates_span.count == 1
                 dates_span[0].text.to_s
               end
      end
      date = Date.parse(date) unless date.nil?
      puts "[#{links.count + 1}] #{link}"
      links << { title: title, link: link, date: date, type: type }
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    links
  end

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    title = title(body)
    date = date(body)
    type = body.css('.original_type').text
    bureau_office = bureau_office(body)
    article = body.css('.entry-content').to_s
    teaser = teaser(body)
    with_table = table(article)
    dirty_news = title.blank? || article.blank? || date.blank? || teaser.blank?
    info = {
      title: title,
      date: date,
      link: link,
      type: type,
      bureau_office: bureau_office,
      teaser: teaser,
      article: article,
      with_table: with_table,
      dirty_news: dirty_news
    }
    tags = tags(body)

    [info, tags]
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
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

  def bureau_office(body)
    bureau_office = body.css('.article-meta .article-meta__author-bureau')
    bureau_office = if bureau_office.to_s.index('<br>').blank?
                      bureau_office.text.strip
                    else
                      bureau_office.to_s.split('<br>').last.gsub('</p>', '').strip
                    end
    bureau_office = body.css('.report-meta__author').text if bureau_office.blank?
    bureau_office.blank? ? nil : Nokogiri::HTML.parse(bureau_office).text.strip
  end

  def teaser(body)
    teasers_arr = body.css('.entry-content p')
    teaser = nil
    teasers_arr.each do |item|
      teaser = item.text
      break if teaser.length > 100
    end
    teaser = teaser.gsub('​', '').gsub(' ', ' ').gsub(/\s/, ' ').squeeze(' ') unless teaser.blank?
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

  def tags(body)
    tags_arr = body.css('.related-tags__pills a')
    tags = []
    tags_arr.each do |tag|
      tags << tag.text
    end
    tags
  end
end

