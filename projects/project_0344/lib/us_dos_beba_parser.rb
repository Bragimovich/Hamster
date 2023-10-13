class UsDosBebaParser < Hamster::Parser

  def get_from(file)
    html          = Nokogiri::HTML(file)
    title         = html.at('main article h1').text.strip
    title         = "#{title[0, 202]}..." if title.size > 205
    bureau_office = html.at('main article section p.article-meta__author-bureau')&.text&.strip
    tags          = html.css('div.related-tags div.related-tags__pills a').map(&:text)
    article_noko  = html.at('main article div.entry-content') || html.at('main article div.report__content')
    article_noko.search('img').each(&:remove)
    article_noko.search('script').each(&:remove)
    html.css('div.related-tags').remove

    article = article_noko.children.to_html.strip
    article_noko.at('h2')&.remove

    teaser     = cut_teaser_length(article_noko.text.strip).gsub(' ', ' ').strip
    with_table = article_noko.to_html.include?('<table') && !article_noko.at('table tr')&.text&.include?(article_noko.text[50,100])

    teaser, article = [nil, nil] unless article_noko.text.present?
    dirty_news      = article.nil?

    { title: title, bureau_office: bureau_office, article: article, teaser: teaser,
      with_table: with_table, dirty_news: dirty_news, tags: tags }
  end

  def list(page, take = :all)
    html = Nokogiri::HTML(page)
    return [] if html.css('div.collection-list ul.collection-results').text.strip.empty?

    get_info_for_db(html, take)
  end

  private

  def get_info_for_db(html, take)
    list_items = html.css('div.collection-list ul.collection-results li')
    list_items.map do |li|
      link = li.at('a')['href'][-1] == '/' ? li.at('a')['href'] : "#{li.at('a')['href']}/"
      type = li.at('p.collection-result__date')&.text&.downcase
      date = li.at('.collection-result-meta')&.text&.to_date
      take == :all ? { link: link, date: date, type: type } : link
    end
  end

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
