require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    body = body.css('#sing-post-content-news > div > div > div > div > div')
    title = title(body)
    return if title.blank?
    date = date(body)
    article = article(body)
    teaser = teaser(article)
    teaser = teaser == '' ? nil : teaser
    article = article.to_s
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
    title = body.css('.elementor-page-title .elementor-heading-title').text.strip
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
    date = body.css('.post-tmpl-date.elementor-widget.elementor-widget-post-info > div > ul > li > span')
    date = date[0].text.strip
    return if date.blank?
    DateTime.parse(date)
  end

  def article(body)
    article = body.css('.elementor-widget.elementor-widget-theme-post-content > div').to_s
    article_end = article.index('###')
    article = article[0, article_end] unless article_end.nil?
    article = Nokogiri::HTML.parse(article).css('.elementor-widget-container')
    article
  end

  def teaser(article)
    teaser = nil
    paragraphs = article.css('p')
    paragraphs.each do |paragraph|
      if !paragraph.text.blank? && paragraph.text.length > 50 && !paragraph.text.include?('Click here')
        teaser = paragraph
        break
      end
    end
    if teaser.blank?
      rows = article.css('table tr')
      rows.each do |row|
        if !row.text.blank? &&row.text.length > 50
          teaser = row
          break
        end
      end
    end
    if teaser.blank? && !article.blank?
      teaser = article
    end
    return if teaser.blank?
    teaser = teaser.to_s.strip
    teasers = teaser.split('<br>')
    teasers.each do |item|
      unless item.blank?
        item = Nokogiri::HTML.parse(item).text.gsub(/\s/,' ')
        item = item.gsub(' ',' ').gsub(' ',' ').gsub('­','').gsub('‎','').squeeze(' ').strip
        if item.length > 50
          teaser = item
          break
        end
      end
    end
    teaser = Nokogiri::HTML.parse(teaser).text.strip
    teaser = teaser.gsub(/\s/,' ').gsub('‎','').gsub(' ',' ').gsub('­','').squeeze(' ').strip
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

  def table(page)
    page.to_s.include? '</table>'
  end

  def page_items(hamster)
    links = []
    items = Nokogiri::HTML.parse(hamster.body).css('.elementor-row .jet-listing-grid .jet-listing-grid__item .jet-engine-listing-overlay-link')
    items.each do |item|
      url = item['href']
      logger.info "[#{links.count + 1}] #{url}"
      links << url
    end
    links
  end
end
