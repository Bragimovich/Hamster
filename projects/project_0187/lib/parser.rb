require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    body = body.css('.evo-content')
    title = title(body)
    return if title.blank?
    date = date(body, link)
    type = type(body)
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
      type: type,
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
    title = body.css('.block--drupaltheme61-republicans-judiciary-page-title h1').text.to_s.strip
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
    teasers = article.css('p', 'div')
    if teasers.empty?
      if article.to_s.index('<br>').nil?
        teaser = article.text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip
      else
        teaser = article.to_s
        teaser = teaser[0, teaser.index('<br>')]
        teaser = Nokogiri::HTML.parse(teaser)
        teaser = teaser.text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip
      end
    else
      teaser_count = teasers.count
      teaser = ''
      (0..teaser_count).each do |item|
        teaser = teasers[item].text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip unless teasers[item].nil?
        break if teaser != '' && teaser.length > 50
      end
    end
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
      teaser_new_length = ids.select{ |id| id <= 600 }.max
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
    article = body.css('.block--drupaltheme61-republicans-judiciary-content .evo-in-the-news__body')
    article = body.css('.block--drupaltheme61-republicans-judiciary-content .evo-press-release__body') if article.blank?
    article
  end

  def date(body, link)
    date = body.css('.block--drupaltheme61-republicans-judiciary-content .evo-create-type div')[0].text.strip
    return if date.blank?
    Date.parse(date)
  rescue StandardError => e
    message = "PAGE: #{link}\nError: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def type(body)
    body.css('.block--drupaltheme61-republicans-judiciary-content .evo-create-type div')[1].text.strip.downcase
  end

  def table(body)
    body.to_s.include? '</table>'
  end

  def page_items(hamster)
    links = []
    items = Nokogiri::HTML.parse(hamster.body).css('.evo-view-evo-news .evo-views-row-container .evo-views-row .evo-media-object .media-body .h3 a')
    items.each do |item|
      link = "https://judiciary.house.gov#{item['href']}"
      logger.info "[#{links.count + 1}] #{link}"
      links << link
    end
    links
  end
end

