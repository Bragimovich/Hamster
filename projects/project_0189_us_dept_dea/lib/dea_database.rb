# frozen_string_literal: true


def add_tags(news)

  news_tags = news[:tags]

  existed_tags = {}
  DeaTags.where(tag:news_tags).map {|row| existed_tags[row.tag] = row.id }

  news_linked_tags = []
  news_tags.each do |news_tag|
    if news_tag.in?(existed_tags.keys)
      news_linked_tags.push({
                            article_link: news[:link],
                            tag_id: existed_tags[news_tag]
                          })
    else
      DeaTags.insert({tag:news_tag})
      tag_id = DeaTags.find_by(tag:news_tag).id
      news_linked_tags.push({
                              article_link: news[:link],
                              tag_id: tag_id
                            })
    end

  end

  DeaTagsArticleLinks.insert_all(news_linked_tags) if !news_linked_tags.empty?

end


def insert_to_db(news_to_db)
  Dea.insert_all(news_to_db)
end

def get_existing_links(links)
  existing_links = []
  lawyers = Dea.where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end

