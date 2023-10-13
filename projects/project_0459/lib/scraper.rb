# frozen_string_literal: true
require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser = Parser.new
    @keeper = keeper
  end

  def scrape_new_data(letter, page, subfolder_path)
    url = "https://www.padisciplinaryboard.org/api/attorneysearch?pageNumber=#{page}&pageLength=500&last=#{letter}"
    connect_to(url:url)&.body
  end

  def save_inner_record(attorney_id, subfolder)
    uri = "https://www.padisciplinaryboard.org/for-the-public/find-attorney/attorney-detail/#{attorney_id}"
    connect_to(url:uri)&.body
  end

  private

  attr_accessor :keeper, :parser

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
end
