# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_pr_list(page_body)
    doc = Nokogiri::HTML page_body
    doc.css('h4 a').map {|el| "#{FMC_URL}#{el.values.first}"}
  end

  def parse_single_pr(link, pr_response)
    html_doc = Nokogiri::HTML pr_response
    art = html_doc.css('article')
    title = art.css('.entry-title').text
    teaser = art.children.drop(5).first.text

    pr_article = ''
    art.children.drop(5).each {|item| pr_article += item.to_s}
    article = pr_article.strip.gsub('<br>', '\n').gsub(')--', '').gsub(160.chr("UTF-8"), '')

    pub_date = art.css('time').children.text
    date = nil
    begin
      date = Date.strptime(pub_date.strip, '%B %d, %Y')
    rescue StandardError => e
      [STARS,  e].each {|line| logger.error(line)}
    end
    with_table = art.css('table').any?
    dirty_news = pr_article.strip.empty? || false # need to replace FALSE wit another_language_check
    article_page_data = {
      link:             link,
      article:          article,
      date:             date,
      title:            title,
      with_table:       with_table,
      dirty_news:       dirty_news,
      teaser:           teaser,
      data_source_url:  link
    }
  end
end
