require 'scylla'

class Parser

  def get_table_rows(file_content)
    press_release = Nokogiri::HTML(file_content)
    press_release.css('.view-congress-press-releases .views-row')
  end

  def get_url_from_row(press_release)
    press_release.css('.views-field-title a').first['href']
  end

  def get_info_from_details_page(file_content)
    article_body, article_subtitle = parse_article(file_content)
    press_release = Nokogiri::HTML(file_content)
    article_teaser = press_release.css('.views-field-body .field-content')&.text&.strip
    if (article_teaser.length < 50) and !article_body.blank?
      items = article_body.css('p')
      article_teaser = items[0]&.text.blank? ? items[1]&.text&.strip : items[0]&.text&.strip
    end
    
    teaser = nil   
    
    if article_teaser.present?
      teaser = TeaserCorrector.new(article_teaser).correct    
    end

    date_xpath = "//div[@class='panel-pane pane-node-created']/div//text()"
    {
      title: press_release.xpath("//*[@id='page-title']//text()")&.text&.strip,
      # subtitle: article_subtitle.text.strip,
      teaser: teaser,
      article: article_body&.to_s,
      date: press_release.xpath(date_xpath)&.first&.text&.strip,
      dirty_news: (article_body.blank? or article_body&.text.blank? or (article_body&.text&.language != "english")),
      with_table: article_body.css('table').present?
    }
  end


  def parse_article(file_content)
    article = Nokogiri::HTML(file_content).css('.panel-panel')
    [article.css('.field-name-body'), article.css('.field-name-field-congress-subtitle')]
  end

  def get_article_categories(file_content)
    article = Nokogiri::HTML(file_content).css('.panel-panel')
    article_cats = []
    article.css('.pane-node-field-congress-issues a').each do |issue|
      article_cats << issue&.text
    end
    article_cats
  end

  def parse_categories(page)
    issues = Nokogiri::HTML(page).css('.view-congress-issues .views-row')
    list_of_categories = []
    issues.each do |issue|
      list_of_categories << issue.css('a')&.text
    end
    list_of_categories
  end

end