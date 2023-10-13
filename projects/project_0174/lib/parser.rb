require_relative '../lib/message_send'
class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    return if link == 'https://www.gsa.gov'
    body = body.css('.node-content')
    body = body.css('.main-content') if body.blank?
    title = title(body)
    date = date(body)
    article = article(body)
    teaser = teaser(article)
    city, state = city_state(article)
    article = article.to_s
    with_table = table(article)
    dirty_news = title.blank? || date.blank? || article.blank? || teaser.blank?
    info = {
      title: title,
      teaser: teaser,
      article: article,
      link: link,
      city: city,
      state: state,
      date: date,
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
    body.css('h1').text.to_s
  end

  def teaser(article)
    teasers = article.css('p', 'div')
    unless teasers.empty?
      teaser_count = teasers.count
      teaser = ''
      (0..teaser_count).each do |item|
        teaser = teasers[item].text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip unless teasers[item].nil?
        break if teaser != '' && teaser.length > 50
      end
      cut_teaser_length(teaser)
    end
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
      teaser_new_length = ids.select{ |id| id <= 600 }.max
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
    article = body
    article.css('.datetime').remove unless article.css('.datetime').blank?
    article.css('h1').remove unless article.css('h1').blank?
    article.css('p em')[0].remove unless article.css('p em').blank?
    article.css('.rtecenter')
    article
  end

  def date(body)
    Date.parse(body.css('.datetime').text)
  end

  def city_state(body)
    article = body
    article.css('.datetime').remove unless article.css('.datetime').blank?
    article.css('h1').remove unless article.css('h1').blank?
    article.css('p em')[0].remove unless article.css('p em').blank?
    article = article.to_s
    if !article.index('-').nil?
      city_state = Nokogiri::HTML.parse(article[0, article.index('-')]).text.strip
      city_state = nil if city_state.length > 30
    else
      city_state = nil
    end
    city = nil
    state = nil
    unless city_state.nil?
      city_index = city_state.index(/,|\(/)
      if !city_index.nil?
        city = city_state[0, city_index].strip
        state = city_state[city_index + 1, city_state.length].gsub(')', '').strip
      else
        city = city_state
      end
    end
    [city, state]
  end

  def table(body)
    body.to_s.include? '</table>'
  end

  def pages(hamster)
    Nokogiri::HTML.parse(hamster.body).css('#content-wrapper div p a')
  end

  def page_items(hamster)
    Nokogiri::HTML.parse(hamster.body).css('.usa-table tr .news-link')
  end
end
