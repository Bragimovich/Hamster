require_relative '../lib/parser'

class ProjectParser < Parser
  URL = 'https://ustr.gov/about-us/policy-offices/press-office/news'
  MAIN_URL = "https://ustr.gov"

  def article_links
    @article_links
  end

  def pages_links
    elements_list(type: 'link', css: 'li.pager__item a', url_prefix: URL)
  end

  def next_link
    links = elements_list(type: 'link', css: 'li.pager__item--next', url_prefix: URL)
    links.blank? ? nil : links[0]
  end

  def last_link
    links = elements_list(type: 'link', css: 'li.pager__item--last a', url_prefix: URL)
    links.blank? ? nil : links[0]
  end

  def years_archive_links
    links = elements_list(type: 'link', css: 'div.clear-block p a', url_prefix: MAIN_URL)
    links = elements_list(type: 'link', css: 'div.field__item p a', url_prefix: MAIN_URL) if links.blank?
    links
  end

  def years_fs_links
    elements_list(type: 'link', url_prefix: MAIN_URL, css: 'a.child')
  end

  def fs_titles_data
    titles = elements_list(type: 'text', css: 'ul.listing li a')
    dates = elements_list(type: 'date', css: 'ul.listing li', child: 0)
    links = elements_list(type: 'link', css: 'ul.listing li a', url_prefix: MAIN_URL)
    @article_links = links
    links.map.with_index do |_, index|
      {
        title: titles[index],
        link: links[index],
        date: dates[index]
      }
    end
  end

  def titles_data
    titles = elements_list(type: 'text', css: 'div.views-field-title')
    types = elements_list(type: 'text', css: 'div.views-field-field-document-type', downcase: true )
    dates = elements_list(type: 'date', css: 'time.datetime')
    links = elements_list(type: 'link', css: 'div.views-field-title a', url_prefix: MAIN_URL)
    @article_links = links
    links.map.with_index do |_, index|
      {
        title: titles[index],
        link: links[index],
        type: types[index],
        date: dates[index]
      }
    end
  end

  def article_data
    article = elements_list(type: 'html', css: 'article.node--type-general div.field--type-text-with-summary', range: 0)
    teaser = elements_list(type: 'teaser', css: 'article.node--type-general div.field--type-text-with-summary', range: 0)
    with_table = @html.css('article table').empty? ? 0 : 1
    (article.blank? || teaser.blank?) ? dirty_news = 1 : dirty_news = 0
    {
      dirty_news: dirty_news,
      with_table: with_table,
      teaser: teaser,
      article: article
    }
  end
end
