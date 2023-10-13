# frozen_string_literal: true

TEASER_LEN = 150

class Parser < Hamster::Parser
  def links(source)
    page = Nokogiri::HTML source
    page.css('div.pubdate a').map {|a| a.attributes['href'].value}
  end

  def parse(url, pr_response)
    html_doc  = Nokogiri::HTML pr_response
    date      = Date.strptime(html_doc.css('p.subtitle').text, '%m/%d/%Y')
    title     = html_doc.css('h1').text
    content   = html_doc.css('div.ms-rtestate-field')
    article   = content.to_s
    teaser    = proper_teaser(content.text, TEASER_LEN)
    article_data = {title:  title,
                    teaser: teaser,
                    article: article,
                    date: date,
                    link: url}
  end

  def proper_teaser(str, len)
    tmp = (str.split.map {|el| el.strip}).join(' ')[0..len]
    teaser = tmp[0..tmp.rindex(' ')-1] + '…'
  end
end
