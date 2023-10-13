# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML(doc)
  end

  def next_page
    @html.css("div.item-list ul.pager > li.pager-next").present?
  end

  def press_release_list
    @html.css("div.pane-content").first.css("div.view-content > div").map do |item|
      title = item.css(".views-field-title").text.squish
      href = item.css(".views-field-title a").attr("href").text
      teaser = item.css(".views-field-body").text.squish
      date = DateTime.parse(item.css(".views-field-created").text.squish).strftime("%Y-%m-%d")
      type = item.css(".views-field-field-congress-article-type").text.squish
      
      { 
        url: href,
        title: title, 
        teaser: teaser, 
        type: type, 
        date: date
       }
    end
  end

  def release_data
    article = @html.css("div[class='panel-pane pane-entity-field pane-node-body']").css('.pane-content')
    with_table = article.css('table').present? ? 1 : 0

    {
      article: article.to_s,
      with_table: with_table
    }
  end
end
