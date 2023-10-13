require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_items(hamster)
    links = []
    items = Nokogiri::HTML.parse(hamster.body).css('.field_body p a')
    items.each do |item|
      link = item[:href]
      title = item.text
      next if link.include? '#'
      link = "https://www.justice.gov#{link}" if link[0] == '/'
      link = link.gsub('/justice.gov', '/www.justice.gov')
      next unless link.include? 'justice.gov'
      links << {title: title, link: link}
    end
    links
  end

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    link = link(body)
    title = title(body)
    body = body.css('.node__content')
    subtitle = subtitle(body)
    date = date(body)
    article = article(body)
    teaser = teaser(article)
    city, state = city_state(teaser)
    contact_info = contact_info(body)
    with_table = table(article)
    dirty_news = title.blank? || article.blank? || teaser.blank? || date.blank?
    info = {
      title: title,
      subtitle: subtitle,
      date: date,
      link: link,
      city: city,
      state: state,
      teaser: teaser,
      article: article,
      contact_info: contact_info,
      with_table: with_table,
      dirty_news: dirty_news
    }
    bureau_offices = bureau_offices(body)
    tags = tags(body)
    [info, bureau_offices, tags]
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end

  def link(body)
    body.css('.original_link').text.strip
  end

  def title(page)
    title = page.css('.original_title').text.strip
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

  def subtitle(body)
    subtitle = body.css('.node-subtitle').text
    subtitle = nil if subtitle == ''
    subtitle
  end

  def date(body)
    date = body.css('.date-display-single')
    return if date.blank?
    date = date[0]['content']
    Date.parse(date)
  end

  def article(body)
    body.css('.field--name-field-pr-body').to_s
  end

  def table(article)
    article.include? '</table>'
  end

  def teaser(article)
    article = Nokogiri::HTML.parse(article)
    teasers = article.css('p')
    if teasers.blank?
      if article.to_s.index('<br>').nil?
        teaser = article.text.to_s.gsub(/\s/, ' ').squeeze(' ').strip
      else
        teaser = article.to_s
        teaser = teaser[0, teaser.index('<br>')]
        teaser = Nokogiri::HTML.parse(teaser)
        teaser = teaser.text.to_s.gsub(/\s/, ' ').squeeze(' ').strip
      end
    else
      teaser = nil
      teasers.each do |item|
        teaser = item.text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip unless item.blank?
        break if !teaser.blank? && teaser.length > 100
      end
    end
    teaser = teaser.gsub('​', '').gsub(' ', ' ').squeeze(' ')
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

  def city_state(teaser)
    city_state = nil
    index_1 = teaser.index('—')
    index_2 = teaser.index('–')
    index_3 = teaser.index('-')
    index_4 = teaser.index(':')
    indexs = [index_1, index_2, index_3, index_4]
    min_index = indexs.delete_if { |index| index.nil? }.min
    if !index_1.nil? && index_1 < 30 && index_1 == min_index
      city_state_end = teaser.index('—')
      city_state = teaser[0, city_state_end]
    elsif !index_2.nil? && index_2 < 30 && index_2 == min_index
      city_state_end = teaser.index('–')
      city_state = teaser[0, city_state_end]
    elsif !index_3.nil? && index_3 < 30 && index_3 == min_index
      city_state_end = teaser.index('-')
      city_state = teaser[0, city_state_end]
    elsif !index_4.nil? && index_4 < 30 && index_4 == min_index
      city_state_end = teaser.index(':')
      city_state = teaser[0, city_state_end]
    end
    if city_state.nil?
      city = nil
      state = nil
    elsif city_state.index(',').nil?
      city = city_state.strip
      state = nil
    else
      city_state = city_state.split(',')
      city = city_state[0].strip
      state = city_state[1].strip
    end
    [city, state]
  end

  def contact_info(body)
    body.css('.pr-fields .field--name-field-pr-contact .field__items')
    contact = nil if contact.blank?
    contact
  end

  def bureau_offices(body)
    bureau_offices = []
    items = body.css('.pr-fields .field--name-field-pr-component .field__item')
    items.each do |item|
      bureau_offices << item.text.strip
    end
    bureau_offices
  end

  def tags(body)
    tags = []
    items = body.css('.pr-fields .field--name-field-pr-topic .field__item')
    items.each do |item|
      tags << item.text.strip
    end
    tags
  end
end
