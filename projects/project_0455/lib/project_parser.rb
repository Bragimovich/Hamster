require_relative '../lib/parser'

class ProjectParser < Parser

  def initialize
    super
  end

  MAIN_URL = "https://washingtondc.embaixadaportugal.mne.gov.pt"

  def pages_links
    elements_list(type: 'link', css: 'div.pagination ul li a', url_prefix: MAIN_URL, range: 3..-3)
  end

  def next_link
    elements_list(type: 'link', css: 'li.pagination-next a', url_prefix: MAIN_URL, range: 0)
  end

  def last_link
    elements_list(type: 'link', css: 'li.pagination-end a', url_prefix: MAIN_URL, range: 0)
  end

  def article_links
    elements_list(type: 'link', css: 'td.list-title a', url_prefix: MAIN_URL)
  end

  def titles_data
    titles = elements_list(type: 'text', css: 'td.list-title a')
    dates = elements_list(type: 'date', css: 'td.list-date')
    links = article_links
    links.map.with_index do |_, index|
      {
        title: titles[index],
        link: links[index],
        date: dates[index]
      }
    end
  end

  def article_data
    article = elements_list(type: 'html', css: 'div.item-page', range: 0, child: -1)
    teaser = elements_list(type: 'teaser', css: 'div.item-page', range: 0, child: -1)
    with_table = @html.css('div.item-page table').empty? ? 0 : 1
    {
      dirty_news: @dirty_news[0],
      with_table: with_table,
      teaser: teaser,
      article: article
    }
  end
end
