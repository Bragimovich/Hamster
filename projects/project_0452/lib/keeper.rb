# frozen_string_literal: true

require_relative '../models/sba'

class Keeper < Hamster::Harvester
  def get_count_from_db  # total number of articles in DB
    Sba.connection.execute("SELECT id from sba;").count
  end

  def exists?(item)
    Sba.exists?(link: URL + item["url"])
  end

  def store(article_data)
    pr = Sba.new
    pr.title           = article_data[:title]
    pr.subtitle        = article_data[:subtitle]
    pr.teaser          = article_data[:teaser]
    pr.article         = article_data[:article]
    pr.date            = article_data[:date]
    pr.link            = article_data[:link]
    pr.release_number  = article_data[:release_number]
    pr.program         = article_data[:program]
    pr.contact_info    = article_data[:contact_info]
    pr.type            = article_data[:type]
    pr.dirty_news      = article_data[:dirty_news]
    pr.with_table      = article_data[:with_table]
    pr.save
  rescue StandardError => e
    [STARS,  error_message(e)].each {|line| logger.error(line)}
  end

  # logging backtrase only if not duplicate entry error
  def error_message(e)
    e.message.include?("Duplicate entry") ? e.message : e
  end
end
