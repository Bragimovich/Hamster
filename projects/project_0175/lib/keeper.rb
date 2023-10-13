# frozen_string_literal: true

require_relative '../models/us_fmc'

class Keeper < Hamster::Harvester
  def store(article_data)
    pr = UsFmc.new
    pr.link            = article_data[:link]
    pr.title           = article_data[:title]
    pr.date            = article_data[:date]
    pr.teaser          = article_data[:teaser]
    pr.article         = article_data[:article]
    pr.with_table      = article_data[:with_table]
    pr.dirty_news      = article_data[:dirty_news]
    pr.data_source_url = article_data[:data_source_url]
    pr.save
  rescue ActiveRecord::RecordNotUnique => e
    [STARS,  e.message].each {|line| logger.warn(line)}
  rescue StandardError => e
    [STARS,  e].each {|line| logger.error(line)}
  end
end
