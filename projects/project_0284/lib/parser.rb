require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    title = title(body)
    date = date(body)
    teaser = teaser(body)
    article = article(body)
    city, state, country = city_state(body)
    country = 'US' if country.blank?
    with_table = table(article)
    dirty_news = title.blank? || date.blank? || article.blank? || teaser.blank?
    info = {
      title: title,
      date: date,
      link: link,
      city: city,
      state: state,
      country: country,
      teaser: teaser,
      article: article,
      with_table: with_table,
      dirty_news: dirty_news
    }
    tags_str = tags_str(body)
    [info, tags_str]
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def title(body)
    title = body.css('.original_title').text
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
    date = body.css('.original_date').text
    return if date.blank?
    DateTime.parse(date)
  end

  def teaser(body)
    teaser = body.css('.original_teaser').text
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

  def article(body)
    body.css('.nr-content-area .nr-body').to_s
  end

  def city_state(body)
    city_and_state = body.css('.nr-head .nr-meta span')
    city = city_and_state[0].nil? ? '' : city_and_state[0].text.gsub(',', '').strip
    state = city_and_state[1].nil? ? '' : city_and_state[1].text.gsub(',', '').strip
    country = 'US'
    if state.length > 2
      country = city_and_state[1]['class'].to_s
      state = nil
    end
    city = nil if city.blank?
    state = nil if state.blank?
    [city, state, country]
  end

  def table(article)
    article.include? '</table>'
  end

  def tags_str(body)
    body.css('.original_tags').text
  end

  def tags(page)
    body = Nokogiri::HTML.parse(page)
    items = body.css('p')
    tags = []
    items.each do |item|
      tags << item.text
    end
    tags
  end

  def page_items(hamster)
    links = []
    items = Nokogiri::HTML.parse(hamster.body).css('.news-wrapper')
    items.each do |item|
      link = item.css('.news-content .news-title a')[0]['href'].to_s
      link = "https://www.ice.gov#{link}"
      title = item.css('.news-content .news-title a').text
      date = item.css('.news-content .news-date').text.strip
      date = Date.parse(date)
      tags = item.css('.news-content .news-tag').text.gsub('|','').strip
      teaser = item.css('.news-body').text
      links << {link: link, title: title, date: date, tags: tags, teaser: teaser}
    end
    links
  end

  def tags_parse(hamster)
    tags = []
    page = Nokogiri::HTML.parse(hamster.body)
    tags_items = page.css('#edit-field-news-release-topics-tag-target-id option')
    tags_items.each do |item|
      tag = item.text.strip
      if tag != 'Topic'
        tags << tag
      end
    end
    tags
  end
end
