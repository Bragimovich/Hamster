# frozen_string_literal: true

require_relative '../models/ntsb'

class Keeper < Hamster::Harvester
  def initialize
    super
  end

  def store(article_data)
    pr = Ntsb.new
    pr.title    = article_data[:title]
    pr.teaser   = article_data[:teaser]
    pr.article  = article_data[:article]
    pr.date     = article_data[:date]
    pr.link     = article_data[:link]
    pr.save
  rescue StandardError => e
    [STARS,  error_message(e)].each {|line| logger.error(line)}
  end

  # logging backtrase only if not duplicate entry error
  def error_message(e)
    e.message.include?("Duplicate entry") ? e.message : e
  end
end
