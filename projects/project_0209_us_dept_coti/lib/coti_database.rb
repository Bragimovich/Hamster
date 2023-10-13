# frozen_string_literal: true


def insert_to_db(news_to_db)
  begin
    Coti.insert_all(news_to_db)
  rescue
    news_to_db.each do |news|
      p news[:link]
      Coti.insert(news)
    end
  end
end

def get_existing_links(links)
  existing_links = []
  lawyers = Coti.where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end


def categories_db
  categories_to_id = {}
  CotiCategories.all().each { |row| categories_to_id[row.category]=row.id }
  categories_to_id
end


def add_categories_to_links(news, category_to_id)
  link = news[:link]
  categories_to_db = []

  news[:categories].each do |category|
    categories_to_db.push({
                            article_link: link,
                            category_id: category_to_id[category]
                          })
  end

  CotiCategoriesArticleLinks.insert_all(categories_to_db) if !categories_to_db.empty?
end
