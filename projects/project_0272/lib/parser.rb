class Parser < Hamster::Parser
  def initialize(content)
    super
    @html = Nokogiri::HTML(content)
  end

  def parse
    link         = html.css('head link').find { |link| link['rel'] == 'canonical' }['href'].sub('/fsa.', '/www.fsa.')
    title        = html.at('div.perc-blog-wrapper h1.perc-blog-title')&.text&.strip
    title        = "#{title[0, 202]}..." if !title.nil? && (title.size > 205)
    date         = html.css('head meta').search('meta').find { |meta| meta['property'] == 'dcterms:created' }['content'].split('T').join(' ')
    article_html = html.at('div.perc-blog-wrapper div.perc-blog-post')
    release_no   = article_html&.at('p')&.text&.include?('Release No.') ? article_html.at('p').text.sub('Release No.', '') : nil
    first_div    = article_html&.at('div') && article_html.at('div').text.size < 1000 ? article_html.at('div') : nil
    contact_raw  = article_html&.at('p') || first_div
    contact_info = contact_raw&.text&.include?('Contact:') ? contact_raw.to_html : nil

    if contact_info.nil? && article_html&.at('div')&.text&.include?('Contact:') && article_html.css('div.rxbodyfield div').size >= 2
      contact_info_raw = article_html.css('div.rxbodyfield div')
      contact_info     = contact_info_raw[0..1].to_html if contact_info_raw[1].to_html.match?(/mailto:/)
    end

    article_html.at('p').remove if article_html&.at('p')&.text&.include?('Release No.')
    article_html&.css('p')&.each do |i|
      i.remove if i.to_html.match?(/Contact:|mailto:/) && article_html.text[0..500].include?(i.text)
    end
    article_html&.css('div')&.each do |i|
      i.remove if i.to_html.match?(/Contact:|mailto:/) && article_html.text[0..500].include?(i.text)
    end
    article_html&.search('img')&.each(&:remove)
    article_html&.search('script')&.each(&:remove)

    article    = article_html.nil? || article_html.text.strip.empty? ? nil : article_html.to_html
    teaser     = article.nil? ? nil : cut_teaser_length(article_html.text.strip.gsub(' ', ' '))
    with_table = !article_html.nil? && article_html.to_html.include?('<table') && !article_html.at('table tr')&.text&.include?(article_html.text[50, 100])
    dirty      = article.nil?

    { title: title, date: date, link: link, article: article, teaser: teaser, contact_info: contact_info,
      release_number: release_no, dirty_news: dirty, with_table: with_table }
  end

  private

  attr_reader :html

  def cut_teaser_length(teaser)
    return if teaser.nil?

    teaser = select_shortest_sentence(teaser)
    teaser = cut_sentence(teaser) if teaser.size > 600
    teaser&.sub(/:$/, '...')
  end

  def select_shortest_sentence(teaser)
    ids = []
    if teaser.size > 600
      sentence_ends = teaser[300..650].scan(/\w{4,}[.]|\w{4,}[?]|\w{4,}[!]/)
      sentence_ends.each do |sentence_end|
        ids << ((teaser.index sentence_end) + sentence_end.size)
      end
      teaser_new_length = ids.select { |id| id <= 600 }.max
      teaser = teaser[0, teaser_new_length] unless teaser_new_length.nil?
    end
    teaser
  end

  def cut_sentence(teaser)
    teaser = teaser[0, 600].strip
    teaser = teaser[0, teaser.size - 1] while teaser.scan(/\w{3,}$/)[0].nil?
    teaser
  end
end
