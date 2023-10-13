class UsDhsFemaParser < Hamster::Parser
  def initialize(page)
    super
    @html = Nokogiri::HTML(page)
  end

  def parse_page
    link           = @html.at('head link')['href']
    title          = @html.at('.grid-container h1.uswds-page-title span').text.strip
    title          = "#{title[0, 202]}..." if title.size > 205
    date_html      = @html.css('.grid-container div.block-views-blockpress-releases-block-2 table tbody td')
    date           = date_html[0].text
    release_number = date_html[-1].text
    article_html   = @html.at('.grid-container article .content-inner-container')

    article_html.search('img').each(&:remove)
    article_html.at('.field--name-field-release-date')&.remove

    article    = article_html.text.strip.empty? ? nil : article_html.at('div').to_html
    teaser     = article.nil? ? nil : cut_teaser_length(article_html.text.strip.gsub(' ', ' '))
    with_table = article_html.to_html.include?('<table') && !article_html.at('table tr')&.text&.include?(article_html.text[50,100])
    dirty_news = article.nil?
    tags       = @html.css('.grid-container article .content-inner-container fieldset.tag-container div a').map(&:text)

    { link: link, title: title, teaser: teaser, article: article, date: date, release_number: release_number,
      dirty_news: dirty_news, with_table: with_table, tags: tags }
  end

  def get_links
    html = @html.css('.view-content')
    return [] if html.empty?

    html.css('.views-field span.field-content a').map { |link| "https://www.fema.gov#{link['href']}" }
  end

  private

  def cut_teaser_length(teaser)
    return if teaser.nil?

    teaser = teaser[0..650]                   if teaser.size > 650
    teaser = select_shortest_sentence(teaser) if teaser.size > 600
    teaser = cut_sentence(teaser)             if teaser.size > 600
    teaser.sub(/:$/, '...')
  end

  def select_shortest_sentence(teaser)
    sentence_ends     = teaser[400..].scan(/\w{4,}[.]|\w{4,}[?]|\w{4,}!|\w{4,}:/)
    ids               = sentence_ends.map { |sentence_end| teaser.index(sentence_end) + sentence_end.size }
    teaser_new_length = ids.select { |id| id <= 600 }.max
    teaser_new_length.nil? ? teaser : teaser[0, teaser_new_length]
  end

  def cut_sentence(teaser)
    teaser = teaser[0, 600].strip
    teaser = teaser[0, teaser.size - 1] while teaser.scan(/\w{3,}$/)[0].nil?
    teaser
  end
end
