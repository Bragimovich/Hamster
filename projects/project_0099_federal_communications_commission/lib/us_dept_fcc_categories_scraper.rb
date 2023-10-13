# frozen_string_literal: true

require_relative '../models/us_dept_fcc_categories'

class UsDeptFccCategoriesScraper <  Hamster::Scraper

  def initialize
    super
    @already_proccessed = UsDeptFccCategories.pluck(:category)
  end

  def scraper
    dataset = UsDeptFccCategories
    filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    response = connect_to(url: "https://www.fcc.gov/news-events/headlines",proxy_filter: filter)
    page_parsed = Nokogiri::HTML(response.body)
    categories = page_parsed.css("div#edit-tid-1-wrapper div.form-item.form-type-bef-checkbox").map{|e| {category: e.text.squish} }
    new_categories = []
    categories.each do |category|
      next if @already_proccessed.include?  category[:category]
      new_categories << category
    end
    UsDeptFccCategories.insert_all(new_categories) if !new_categories.empty?
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
