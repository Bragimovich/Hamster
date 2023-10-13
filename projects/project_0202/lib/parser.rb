# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_pr_list(page_body)
    result = []
    doc = Nokogiri::HTML page_body
    doc.css('.newsblocker').each do |article|
      pr_link = article.css('a').attr('href').value
      title = article.css('.newsie-titler').text.strip
      pr_url = pr_link.gsub('DocumentS', 'documents')

      pub_date = article.css('time').text
      date = nil
      begin
        date = Date.strptime(pub_date.gsub(/-/,'').strip, '%B %d, %Y')
      rescue StandardError => e
        [STARS,  e].each {|line| logger.error(line)}
      end
      # ! need to paginate !
      teaser = article.css('.newsbody').css('p').children[0].text
      article_data = {
          link: "#{URL}#{pr_url}",
          title: title,
          date: date,
          teaser: teaser
      }
      result.push(article_data)
    end
    result.reverse
  end

  def parse_single_pr(article_data, pr_response)
    html_doc = Nokogiri::HTML pr_response
    # art = html_doc.at_css('[id=Table4]')
    div_block = html_doc.css('div.bodycopy')
    pr_article = div_block.to_s

    article = pr_article.strip.gsub('<br>', '\n').gsub(')--', '').gsub(160.chr("UTF-8"), '')

    contact = html_doc.at_css('[id="ctl00_ctl23_ContactMail"]')
    contact_info =
      !!contact ? contact.text + " " + contact.next.text.strip : 'empty'

    td_block = div_block.css('td')
    with_table = (!!td_block && td_block.size > 1)
    dirty_news = (pr_article.strip.empty? || false)   # need to replace FALSE wit another_language_check

    article_page_data = {
      link:             article_data[:link],
      title:            article_data[:title],
      date:             article_data[:date],
      teaser:           article_data[:teaser],
      article:          article,
      with_table:       with_table,
      dirty_news:       dirty_news,
      contact_info:     contact_info,
      data_source_url:  article_data[:link]
    }
  end
end
