require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = body.css('.original_link').text
    title = title(body)
    date = date(body)
    if link.include? 'www.usda.gov'
      article = usda_article(body)
      teaser = teaser(article)
      contact_info = usda_contact_info(body)
      release_number = release_number(body)
      city = usda_city(teaser)
    elsif link.include? 'www.rd.usda.gov'
      article = rd_usda_article(body)
      teaser = teaser(article)
      contact_info = rd_usda_contact_info(body)
      release_number = nil
      city = rd_usda_city(body)
    end
    article = article.to_s
    with_table = table(article)
    dirty_news = title.blank? || date.blank? || article.blank? || teaser.blank? || teaser.length < 50
    info = {
      title: title,
      teaser: teaser,
      article: article,
      date: date,
      link: link,
      contact_info: contact_info,
      release_number: release_number,
      city: city,
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
    DateTime.parse(date)
  end

  def usda_article(body)
    article = body.css('article > div')
    article = article.to_s.gsub(/\t|\n/, "\n").squeeze("\n")
    end_index = article.to_s.index('<p>#</p>')
    article = article[0, end_index] unless end_index.nil?
    article = Nokogiri::HTML.parse(article).css('div')
    article
  end

  def rd_usda_article(body)
    article = body.css('.layout__region--content .field__item')
    article = article.to_s.gsub(/\t|\n/, "\n").squeeze("\n")
    end_index = article.to_s.index('###')
    article = article[0, end_index] unless end_index.nil?
    article = Nokogiri::HTML.parse(article).css('div')
    article
  end

  def teaser(article)
    teasers = article.css('p')
    if teasers.empty?
      if article.to_s.index('<br>').nil?
        teaser = article.text.to_s.gsub(/\s/, ' ').squeeze(' ').strip
      else
        teaser = article.to_s
        teaser = teaser[0, teaser.index('<br>')]
        teaser = Nokogiri::HTML.parse(teaser)
        teaser = teaser.text.to_s.gsub(/\s/, ' ').squeeze(' ').strip
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

  def usda_contact_info(body)
    body.css('.news-release-info p')[0].to_s
  end

  def rd_usda_contact_info(body)
    contact_info = body.css('.layout__region--first')
    unless contact_info.blank?
      contact_info = contact_info[0]
      contact_info.css('.block-field-blocknodenews-releasefield-city').remove
      contact_info.css('.block-field-blocknodenews-releasefield-publish-date').remove
      contact_info.css('.block-extra-field-blocknodenews-releasecontent-moderation-control').remove
      contact_info.to_s
    end
  end

  def release_number(body)
    release_number = body.css('.news-release-info div')
    return if release_number.blank?
    release_number = release_number[1].text
    return if release_number.blank?
    release_number.gsub('Release No.', '').strip
  end

  def rd_usda_city(body)
    city = body.css('article div div .block-field-blocknodenews-releasefield-city .field--name-field-city .field__item')[0]
    if city.nil?
      nil
    else
      city.text.strip
    end
  end

  def usda_city(teaser)
    city = teaser.split(',')[0]
    return if city.blank?
    city = city.gsub('(', '').strip
    city.split('–')[0].strip
  end

  def table(article)
    article.to_s.include? '</table>'
  end

  def page_items(hamster)
    links = []
    items = Nokogiri::HTML.parse(hamster.body).css('.region-content .view-content .views-row')
    items.each do |item|
      date = item.css('.views-field-field-publish-date').text.gsub(/\D+/, '')
      next if date.blank?
      date = Date.strptime(date, '%m%d%Y')
      link = item.css('div span a')[0]['href']
      link = 'https://www.rd.usda.gov' + link if link[0] == '/'
      link = link.gsub(/^http:/, 'https:')
      next if link.include? '/sites/'
      next if link.include? '/files/'
      next if link.include? 'commerce.gov'
      next if link.include? 'epa.gov'
      next if link.include? '.xml'
      next if link.include? 'content.govdelivery.com'
      next if link.blank?
      title = item.css('div span a').text
      links << {date: date, link: link, title: title}
    end
    links
  end
end
