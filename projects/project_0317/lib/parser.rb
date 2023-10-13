require_relative '../lib/message_send'

class Parser < Hamster::Harvester

  def page_items(hamster)
    page = Nokogiri::HTML.parse(hamster.body)
    links = []
    items = page.css('.wpb_wrapper .posts-listing article')
    items.each do |item|
      link = item.css('.post-title a')[0]['href']
      title = item.css('.post-title a').text.to_s.strip
      date = item.css('.post-meta time')[0]['datetime']
      date = Date.parse(date)
      links << {title: title, link: link, date: date}
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
    return if link == 'https://homeland.house.gov/test-blog-post'
    title = title(body)
    date = date(body)
    article = article(body)
    return if article.blank?
    teaser = teaser(body)
    with_table = table(article)
    dirty_news = title.blank? || article.blank? || teaser.blank?
    info = {
      title: title,
      date: date,
      link: link,
      teaser: teaser,
      article: article,
      with_table: with_table,
      dirty_news: dirty_news
    }
    info
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
    date = Date.parse(date)
    date
  end

  def teaser(body)
    teasers_arr = body.css('article .article-content p')
    teaser = nil
    teasers_arr.each do |item|
      teaser = item.text
      break if teaser.length > 100
    end
    teaser = teaser.gsub('​', '').gsub(' ', ' ').gsub(/\s/, ' ').squeeze(' ')
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
      teaser_new_length = 600 if !teaser_new_length.nil? && teaser_new_length < 60 #modify by igor sas
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
    article = body.css('article .article-content')
    article = article.to_s.gsub(160.chr('UTF-8'), ' ').squeeze(' ')
    article_end = article.index('###')
    article = article[0, article_end] unless article_end.nil?
    article = Nokogiri::HTML.parse(article).css('.article-content').to_s
    article
  end

  def table(article)
    article.include? '</table>'
  end
end
