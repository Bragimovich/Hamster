class Parser < Hamster::Parser

  def initialize(**page)
    super
    @html  = Nokogiri::HTML(page[:html])
  end

  def parse
    link         = html.css('head link').find { |link| link['rel'] == 'canonical' }['href'].sub('http', 'https')
    header_html  = html.at('#block-arpae-content .container .row')
    title        = header_html.at('h2').text.strip
    title        = "#{title[0, 202]}..." if title.size > 205
    subtitle     = html.at('span.subtitle').text.strip.gsub(' ', ' ')
    subtitle     = nil if subtitle == ''
    date         = html.at('.small-blk-label time')['datetime'].to_datetime
    article_html = html.at('#block-arpae-content .news-body')
    article_html = article_html.children[0].text.strip == '' ? article_html.at('div') : article_html

    article_html.search('img').each(&:remove)
    contacts = Nokogiri::HTML.fragment('')
    article_html.children.each do |item|
      contacts << item if item.to_html.match?(/News Media Contact|tel:/) && article_html.text[0..500].include?(item.text)
    end

    contact_info = correct_contacts(contacts)

    %w[January February March April May June July August September October November December].each do |month|
      article_html.children[0..1].each do |p|
        p.remove if p.text.strip.empty? || (p.text.include?(month) && p.to_html.size < 80)
      end
    end
    article_html.children.each { |p| p.remove if p.text.match?(/##|# #/) && p.text.size < 7 }

    article    = article_html.text.strip.empty? ? nil : article_html.to_html
    teaser     = TeaserCorrector.new(article_html.text).correct.gsub(' ', ' ').strip
    with_table = article_html.to_html.include?('<table') && !article_html.at('table tr')&.text&.include?(article_html.text[50, 100])
    dirty      = article.nil?

    { title: title,  subtitle: subtitle, date: date, link: link, article: article, teaser: teaser,
      contact_info: contact_info, dirty_news: dirty,  with_table: with_table }
  end

  def get_news_links
    html.css('.container .bold-link a').map { |i| 'https://arpa-e.energy.gov' + i['href'] } unless html.css('.container').empty?
  end

  private

  attr_reader :html

  def correct_contacts(contacts)
    return if contacts.text.empty?

    if contacts.text.include?('For Immediate Release')
      str_start    = contacts.children.to_html.index('For Immediate Release')
      str_end      = contacts.children.to_html.size
      str_del      = contacts.to_html[str_start..str_end - 5]
      str_contacts = contacts.to_html
      !str_contacts[0..40].include?('For Immediate Release') ? str_contacts.split(str_del).join : str_contacts
    else
      contacts.to_html.strip
    end
  end
end
