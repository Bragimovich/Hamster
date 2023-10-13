class Parser < Hamster::Parser
  def initialize(page)
    super
    @html = Nokogiri::HTML(page)
  end

  def parse
    link        = html.css('head meta').find { |m| m['property'] == 'og:url' }['content']
    title       = html.at('h2.newsie-titler').text.strip
    date        = Date.parse(html.at('div.topnewstext').text.strip.split("\n")[1].strip)
    teaser_raw  = html.at('div.bodycopy').text.strip[0..700].gsub(/\s+/, ' ')
    teaser      = cut_teaser_length(teaser_raw)
    article_raw = html.at('div.bodycopy')
    article_raw.search('img').each(&:remove)
    tables = article_raw.css('table')
    tables.each { |i| i.remove if i.text.strip.empty? }
    with_table = tables.size > 1 || (tables.size == 1 && teaser_raw != tables.at(0).text.strip[0..700].gsub(/\s+/, ' '))
    article    = article_raw.children.to_html.strip.gsub(/ {2,}/, ' ')
    dirty      = article.nil?

    { title: title, date: date, link: link, article: article, teaser: teaser, dirty_news: dirty, with_table: with_table }
  end

  def parse_old
    link         = html.css('head meta').find { |m| m['property'] == 'og:url' }['content']
    title        = html.at('#press h1.main_page_title').text.strip
    title        = "#{title[0, 202]}..." if title.size > 205
    date         = formalize_date(html.at('#press span.date')&.text)
    article_html = html.at('#press')
    article_html.children.each do |item|
      item.remove if item.to_html.match?(/<span class="date|<h1 class="main_page_title/)
    end
    article_html.search('img').each(&:remove)
    contacts = Nokogiri::HTML.fragment('')
    contact  = false
    article_html.children.each do |item|
      contacts << item if contact
      contact = true if item.text.include?('Press Contact')
    end

    contact_info = contacts.text.empty? || contacts.to_html.size > 1000 ? nil : contacts.to_html
    article_html = remove_grates(article_html)
    article      = article_html.text.strip.empty? ? nil : article_html.to_html
    teaser       = article.nil? ? nil : cut_teaser_length(article_html.text.strip.gsub(' ', ' '))
    with_table   = article_html.to_html.include?('<table') && !article_html.at('table tr')&.text&.include?(article_html.text[50,100])
    dirty        = article.nil?

    { title: title, date: date, link: link, article: article, teaser: teaser, contact_info: contact_info,
      dirty_news: dirty, with_table: with_table }
  end

  def get_news_links
    links_raw = html.css('h2.newsie-titler a')
    return [] if links_raw.empty?

    links_raw.map { |i| "https://naturalresources.house.gov/news/#{i['href']}" }
    #return [] if html.css('#newscontent #press').empty?
    #html.css('#newscontent #press h2.title a').map{ |i| "https://naturalresources.house.gov" + i['href'] }
  end

  private

  attr_reader :html

  def remove_grates(block)
    return if block.nil?

    all_remove = false
    block.children.each do |item|
      all_remove = true if item.text.size < 15 && item.text.include?('Press Contact')
      item.remove if all_remove
    end
  end

  def cut_teaser_length(teaser)
    return if teaser.nil?

    teaser = select_shortest_sentence(teaser)
    teaser = cut_sentence(teaser) if teaser.size > 600
    teaser&.sub(/:$/, '...')
  end

  def select_shortest_sentence(teaser)
    ids = []
    if teaser.size > 600
      sentence_ends = teaser[300..700].scan(/\w{4,}[.]|\w{4,}[?]|\w{4,}[!]/)
      sentence_ends.each do |sentence_end|
        ids << ((teaser.index sentence_end) + sentence_end.size)
      end
      teaser_new_length = ids.select { |id| id <= 600 }.max
      teaser = teaser[0, teaser_new_length] if !teaser_new_length.nil?
    end
    teaser
  end

  def cut_sentence(teaser)
    teaser = teaser[0, 600].strip
    teaser = teaser[0, teaser.size - 1] while teaser.scan(/\w{3,}$/)[0].nil?
    teaser
  end

  def formalize_date(date)
    return if date.nil?

    date_array = date.split('.')
    year = "20#{date_array.pop}"
    date_array.unshift(year).join('-')
  end
end
