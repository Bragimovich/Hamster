require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    title = title(body)
    return if title.blank?
    date = date(body, link)
    article = article(body)
    teaser = teaser(article)
    teaser = teaser == '' ? nil : teaser
    with_table = table(article)
    article = article.to_s.squeeze(' ').strip
    dirty_news = title.blank? || date.blank? || article.blank? || teaser.blank?
    info = {
      title: title,
      teaser: teaser,
      article: article,
      date: date,
      link: link,
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
    body.css('#block-greenhouse-page-title .page-header').text.to_s.strip
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

  def article(page)
    page.css('.article__body')
  end

  def date(body, link)
    begin
      date = body.css('.article__created')
      date = date[0]['content'].to_s[0,10] unless date.blank?
      if date.blank?
        date = body.css('.author-information p')
        date = date.text.to_s unless date.blank?
      end
      Date.parse(date.to_s)
    rescue StandardError => e
      message = "PAGE: #{link}\nError: #{e.message}\nBacktrace:#{e.backtrace}".red
      logger.error message
      message_send(message)
      nil
    end
  end

  def table(body)
    body.to_s.include? '</table>'
  end

  def page_items(hamster)
    page = Nokogiri::HTML.parse(hamster.body)
    items = page.css('.block--content .article__field-image a')
    items_btn = page.css('.block--content .btn')
    [items, items_btn]
  end
end
