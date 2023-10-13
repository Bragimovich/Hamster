require_relative '../lib/parser'

class ProjectParser < Parser
  URL = 'https://hcr.ny.gov/pressroom'
  MAIN_URL = "https://hcr.ny.gov"

  def next_link
    elements_list(type: 'link', url_prefix: URL, css: 'li.pager__item--next a', range: 0)
  end

  def last_link
    elements_list(type: 'link', url_prefix: URL, css: 'li.pager__item--last a', range: 0)
  end

  def find_element(arr)
    arr.reject(&:blank?).first
  end

  def titles_data
    block_css = 'div.webny-teaser-content-wrapper__details'
    data = html.css(block_css).map do |html|
      link = find_element(elements_list(html: html, type: 'link', url_prefix: MAIN_URL, css: "div.webny-teaser-title a"))
      date = find_element(elements_list(html: html, type: 'date', css: 'div.news-listing-date'))
      time = find_element(elements_list(html: html, type: 'time', css: 'div.news-listing-time'))
      date = @converter.string_to_date(date, time)
      type = find_element(elements_list(html: html, type: 'text', css: 'div.webny-teaser-filter-terms', downcase: true))
      next if link.blank?
      {
        link: link,
        type: type,
        date: date
      }
    end
    data.compact
  end

  def article_data
    title = elements_list(type: 'text', css: 'div.hero-news-inner h1 span', range: 0)
    title = elements_list(type: 'text', css: 'div.hero-news-inner h1', range: 0) if title.blank?
    article = elements_list(type: 'html', css: 'div.press-body', range: -1)
    teaser = elements_list(type: 'teaser', css: 'div.news-body div.press-body', range: 0)
    #puts "teaser empty".red; sleep(1000) if article.blank? || teaser.blank?
    #puts "#{html}".red; sleep(1000) if teaser.include? "Ã Â"

    (article.blank? || teaser.blank? || title.blank?) ? dirty_news = 1 : dirty_news = 0
    with_table = @html.css('div.press-body').css("table").empty? ? 0 : 1
    {
      title: title,
      with_table: with_table,
      dirty_news: dirty_news,
      article: article,
      teaser: teaser
    }
  end
end
