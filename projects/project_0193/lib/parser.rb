require_relative '../lib/message_send'
require 'scylla'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    body = body.css('.SiteLayout__main')
    title = title(body)
    return if title.blank?
    date = date(body)
    article = article(body)
    teaser = teaser(article)
    teaser = teaser == '' ? nil : teaser
    with_table = table(article)
    article = article.to_s.squeeze(' ').strip
    dirty_news = title.blank? || article.blank? || teaser.blank? || date.blank? || article.language != "english" || teaser.length < 50
    return if date < Date.parse('2022-08-25')
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
    title = body.css('.Heading__title--press').text.gsub(/\s|\n|\t/,' ').squeeze(' ').strip
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
    date = body.css('.Heading--time')[0]['datetime'].to_s.strip
    return if date.blank?
    Date.parse(date)
  end

  def article(body)
    article = body.css('.js-press-release')
    article = article.to_s.gsub(/\t|\n/, "\n").squeeze("\n")
    end_index = article.to_s.index('###')
    end_index = article.to_s.index('<p style="text-align:center">&nbsp;</p>') if end_index.blank?
    article = article[0, end_index] unless end_index.blank?
    article = Nokogiri::HTML.parse(article).css('.js-press-release')
    article
  end

  def teaser(article)
    teasers = article.css('h2', 'p', 'div' )
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

  def table(body)
    body.to_s.include? '</table>'
  end

  def page_items(hamster)
    Nokogiri::HTML.parse(hamster.body).css('.ArticleBlock__link')
  end

end