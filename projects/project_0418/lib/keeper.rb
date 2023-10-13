require_relative '../models/us_doj_fbi'
require_relative '../models/us_doj_fbi_tags'
require_relative '../models/us_doj_fbi_tag_article_links'
require_relative '../models/us_doj_fbi_bureau_office_article'

class DBKeeper
  def store(hash)
    begin
      UsDojFbi.insert(hash)
    rescue ActiveRecord::ValueTooLong => e
      puts e
    end
  end

  def store_tags(list_of_hash)
    list_of_hash.each do |hash|
      UsDojFbiTags.insert(hash)
    end
  end

  def store_tag_article(list_of_tags , article_link)
    list_of_tags.each do |tag|
      tag_id = UsDojFbiTags.where(tag:tag[:tag] ).first.id

      if tag_id.present?
        hash = {
          article_link: article_link,
          tag_id: tag_id
        }
        UsDojFbiTagArticleLinks.insert(hash)
      end
    end
  end

  def store_bureo_article(list_of_hash)
    list_of_hash.each do |hash|
      UsDojFbiBureauOfficeArticle.insert(hash)
    end
  end
end