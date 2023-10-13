require_relative '../lib/parser'
require_relative '../lib/converter'

class Project_Parser < Parser
  SOURCE = 'https://beta.nsf.gov'

  def initialize
    super
  end

  def pages_amount
    elements_list(type: 'link', css: "li.pager__item--last a", attribute: 'href', range: 0).strip.split('page=').last.to_i
  end

  def filtered_links
    elements_list(type: 'link', css: 'div.latest-news-teaser__headline h3 a', url_prefix: SOURCE)
  end

  def old_teaser
    teaser = html.at('div.field-news-body')&.children&.first&.text&.strip
    teaser = html.at('div.field-news-body')&.children&.[](1)&.text&.strip if teaser.blank?
    teaser = nil if teaser.blank?
    teaser
  end

  def article_data
    date = elements_list(type: 'date', css: 'div.field__content', range: 0)
    #date = DateTime.strptime(str, "%B %d, %Y")
    link = elements_list(type: 'link', css: "meta[property='og:url']", attribute: 'content', range: 0)
    title = elements_list(type: 'text', css: "div.block-field-blocknodenewstitle h1", range: 0)
    kind = elements_list(type: 'text', css: "div.field-news-type", range: 0)
    #teaser = elements_list(type: 'teaser', css: "div.field-news-body", range: 0)
    teaser = old_teaser
    article = elements_list(type: 'html', css: "div.field-news-body", range: 0)
    contact_info = nil

    return nil if teaser.blank? && article.blank?

    {
      title: title,
      teaser: teaser,
      article: article&.strip,
      link: link,
      creator: 'National Science Foundation',
      type: 'press release',
      kind: kind,
      release_no: nil,
      date: date,
      contact_info: contact_info,
      scrape_frequency: 'daily',
      data_source_url: 'https://www.nsf.gov/news/',
      created_by: 'Pospelov Vyacheslav'
    }
  end
end