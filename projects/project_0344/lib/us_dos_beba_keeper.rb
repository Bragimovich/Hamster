require_relative '../models/us_dos_beba'
require_relative '../models/us_dos_beba_runs'
require_relative '../models/us_dos_beba_tags'
require_relative '../models/us_dos_beba_tags_article_links'

class UsDosBebaKeeper
  def initialize
    @count  = 0
    @run_id = run.run_id
  end

  attr_reader :count, :run_id

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  def link_exists?(link)
    UsDosBeba.exists?(link: link)
  end

  def get_links_not_in_db(links)
    links.nil? ? [] : links.select { |link| link unless link_exists?(link) }
  end

  def save_to_db(article_info)
    tags = article_info.delete(:tags)
    article_info[:run_id] = run_id
    UsDosBeba.store(article_info.compact)
    @count += 1
    save_tag(tags, article_info[:link])
  end

  private

  def save_tag(tags, link)
    tags.uniq.each do |tag|
      tags_db = UsDosBebaTags.find_by(tag: tag) || UsDosBebaTags.store(tag: tag)
      UsDosBebaTagsArticleLinks.store({ article_link: link, tag_id: tags_db.id })
    end
  end

  def run
    RunId.new(UsDosBebaRuns)
  end
end
