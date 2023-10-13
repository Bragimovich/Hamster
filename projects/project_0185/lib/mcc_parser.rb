class MccParser < Hamster::Parser
  TASK_NAME = '#185 Millennium Challenge Corporation'
  SLACK_ID  = 'Eldar Eminov'

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
  end

  def get_news_links
    return [] if @html.css('.teaser').empty?

    @html.css('.teaser h3 a').map{ |i| i['href'] }
  end

  def parse_start_info
    return [] if @html.css('.teaser').empty?

    @html.css('li.teaser div.teaser-content').map do |div|
      {link: div.at('h3 a')['href'], date: div.at('p.text-dateline').text}
    end
  end

  def parse_new_data(links_db, date_=nil)
    source_url = 'https://www.mcc.gov/news-and-events'
    link       = source_url + @html.at('head link[rel="canonical"]')['href'].split('news-and-events').last
    return if links_db.include?(link)

    header  = @html.at('#main article header')
    type    = header.at('.text-release-type')&.text&.strip&.downcase
    type    = link.sub(source_url, '').split('/').second if type.nil? || type == ''
    type    = 'press release' if type == 'release'
    title   = header.at('h1').text
    date    = header.at('p.text-dateline')&.text || header.at('p.text-release-date')&.text
    date    = date_ unless date_.nil?
    section = @html.css('#main section')

    section.search('figure').each(&:remove)
    all_remove = false
    section.children.each do |item|
      all_remove = true if !item.text.include?(section.text[20, 600]) && item.to_html.match?(/##|# #|<footer/)
      item.remove if all_remove
    end
    section.search('img').each(&:remove)
    section.search('script').each(&:remove)

    article = section.text.strip.empty? ? nil : section.to_html
    if section.text.strip.size < 10 && (section.text.include?('PDF file') ||
      section.to_html.include?('INCLUDE FOOTNOTES DISPLAY CODE'))
      article = nil
    end
    section.search('h2').each(&:remove)
    teaser     = article.nil? ? nil : cut_teaser_length(section.text.strip.gsub("\n", ' ').gsub(' ', ' ').gsub('  ', ' '))
    contact    = header.css('p.text-byline').to_html
    contact    = nil unless contact.include?('Email') || contact.include?('mailto:')
    dirty      = article.nil?
    with_table = article&.include?('<table') && !section.at('table').text.include?(section.text[100,600])

    { title: title, date: date, link: link, article: article, teaser: teaser, contact_info: contact,
      data_source_url: source_url, type: type, dirty_news: dirty, with_table: with_table }
  end

  private

  def cut_teaser_length(teaser)
    return nil if teaser.nil?

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
end
