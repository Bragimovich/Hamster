require_relative '../models/us_dept_nps'
require_relative '../models/us_dept_nps_tags'
require_relative '../models/us_dept_nps_tags_article_links'
require_relative '../models/us_dept_nps_runs'

class Keeper
  def initialize
    @run_object = RunId.new(NpsRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_links
    Nps.pluck(:link)
  end
  
  def tags_table_insertion(tags,link)
    tags.each do |tag|
      NpsTags.insert(tag: tag,run_id: run_id)
      id = NpsTags.where(:tag => tag).pluck(:id).first
      NpsTALinks.insert(prlog_tag_id: id , article_link: link,run_id: run_id)
    end
  end

  def insert(data)
    Nps.insert_all(data)
  end

  def finish
    @run_object.finish
  end
end
