# frozen_string_literal: true

class EnergyKeeper < Hamster::Scraper
  def initialize(model)
    @model = model
  end

  def fill_main_news_data(link, title, teaser, date, dirty)
    h = {}
    h[:link] = link
    h[:title] = title
    h[:date] = Date.parse(date).to_s if date && date != ''
    h[:teaser] = teaser
    h[:dirty_news] = dirty
    hash = @model.flail { |key| [key, h[key]] }
    @model.store(hash)
    @model.clear_active_connections!
  end

  def add_article(link, article_info)
    proceed_news = @model.find_by(link: link)

    if proceed_news
      article, with_table, contact_info, dirty = article_info
      proceed_news.update(article: article, with_table: with_table, contact_info: contact_info)
      proceed_news.update(dirty_news: dirty) if dirty
    end
    @model.clear_active_connections!
  end
end
