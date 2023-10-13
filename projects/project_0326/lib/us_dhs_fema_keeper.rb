require_relative '../models/us_dhs_fema_tags_article_links'
require_relative '../models/us_dhs_fema_tags'
require_relative '../models/us_dhs_fema'
require_relative '../models/us_dhs_fema_runs'

class UsDhsFemaKeeper
  def initialize
    @count = 0
  end

  attr_reader :count

  def link_exists?(link)
    !UsDhsFema.find_by(link: link).nil?
  end

  def save_to_db(parsed_page)
    return if link_exists?(parsed_page[:link])

    tags = parsed_page.delete(:tags)
    UsDhsFema.store(parsed_page.compact)
    @count += 1
    tags.each do |tag|
      tags_db = UsDhsFemaTags.find_by(tag: tag)
      UsDhsFemaTags.store(tag: tag) if tags_db.nil?

      tag_id = UsDhsFemaTagsArticleLinks.find_by(tag_id: UsDhsFemaTags.find_by(tag: tag).id, article_link: parsed_page[:link])
      data   = { article_link: parsed_page[:link], tag_id: UsDhsFemaTags.find_by(tag: tag).id }
      UsDhsFemaTagsArticleLinks.store(data) if tag_id.nil?
    end
  end

  def run_id
    run.run_id
  end

  def finish
    run.finish
  end

  private

  def run
    RunId.new(UsDhsFemaRuns)
  end
end
