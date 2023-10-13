# frozen_string_literal: true

require_relative '../models/us_dept_committee_on_natural_resources'

class Keeper < Hamster::Harvester
  def store(article_data)
    return nil if article_data[:date] < URL_CHANGE_DATE
    pr = UsDeptCommitteeOnNaturalResources.new
    pr.title           = article_data[:title]
    pr.teaser          = article_data[:teaser]
    pr.link            = article_data[:link]
    pr.date            = article_data[:date]
    pr.article         = article_data[:article]
    pr.contact_info    = article_data[:contact_info]
    pr.dirty_news      = article_data[:dirty_news]
    pr.with_table      = article_data[:with_table]
    pr.data_source_url = article_data[:data_source_url]
    pr.save
  rescue ActiveRecord::RecordNotUnique => e
    [STARS,  e.message].each {|line| logger.warn(line)}
  rescue StandardError => e
    [STARS,  e].each {|line| logger.error(line)}
  end
end
