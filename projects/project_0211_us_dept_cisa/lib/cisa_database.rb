# frozen_string_literal: true


def insert_to_db(news_to_db)
  begin
    Cisa.insert_all(news_to_db)
  rescue
    news_to_db.each do |news|
      p news[:link]
      Cisa.insert(news)
    end
  end
end

def get_existing_links(links)
  existing_links = []
  lawyers = Cisa.where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end


def categories_db
  categories_to_id = {}
  CisaCategories.all().each { |row| categories_to_id[row.category]=row.id }
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

  CisaCategoriesArticleLinks.insert_all(categories_to_db) if !categories_to_db.empty?
end



def add_tags(news)

  news_tags = news[:tags]

  existed_tags = {}
  CisaTags.where(tag:news_tags).map {|row| existed_tags[row.tag] = row.id }

  news_linked_tags = []
  news_tags.each do |news_tag|
    if news_tag.in?(existed_tags.keys)
      news_linked_tags.push({
                              article_link: news[:link],
                              tag_id: existed_tags[news_tag]
                            })
    else
      CisaTags.insert({tag:news_tag})
      tag_id = CisaTags.find_by(tag:news_tag).id
      news_linked_tags.push({
                              article_link: news[:link],
                              tag_id: tag_id
                            })
    end

  end

  CisaTagsArticleLinks.insert_all(news_linked_tags) if !news_linked_tags.empty?

end