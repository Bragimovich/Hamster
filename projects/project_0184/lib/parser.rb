
class Parser < Hamster::Parser

  # @return [Boolean]
  def check_main_page(html:)
    document = Nokogiri::HTML html
    document.css("div[class='views-row views__row'] a").any?
  end

  # @return [Array]
  def get_array_links_from_main_page(html)
    document = Nokogiri::HTML html
    document.css("div[class='views-row views__row'] a").map { |link| "https://www.exim.gov#{link['href']}" }
  end

  # @return [Hash]
  def get_data(html, link)


    document = Nokogiri::HTML html

    return nil if document.css('div.l-page__primary div.block__content').first.text.strip == 'The requested page could not be found.'

    title = document.css('h2.news-item__title').text
    for i in 1..document.css('div.field--text-long p').length
      if document.css("div.field--text-long p:nth-child(#{i})").text.length > 7 then
        teaser = document.css("div.field--text-long p:nth-child(#{i})").text
        break
      end
    end

    article = document.css('div.news-item__body').to_html
    with_table = !(document.css('div.news-item__body table').empty?)? 1 : 0
    date = DateTime.parse(document.css('div.news-item__date span').last.text).to_date.to_s
    contact_info = document.css('div.field--name-field-media-contact').to_html

    {
      title: title,
      teaser: teaser,
      article: article,
      with_table: with_table,
      date: date,
      link: link,
      contact_info: contact_info
    }
  end
end