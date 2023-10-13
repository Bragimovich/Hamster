# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../models/us_dept_hca'


class Scraper < Hamster::Scraper

  URL = "https://agriculture.house.gov/news/documentquery.aspx?"
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser = Parser.new
  end

  def scraper
    already_fetched = UsDeptHca.pluck(:link)
    db_max_date = UsDeptHca.maximum(:date)
    start_date = db_max_date.next_day
    end_date = Date.today
    processed_years = []
    processed_months = []

    (start_date..end_date).each do |date|
      year = date.year
      month = date.month
      next if (processed_years.include? year) && (processed_months.include? month)
      processed_years << year
      processed_months << month

      subfolder = "year_#{year}"
      data_set_path = "#{storehouse}store/#{subfolder}"
      FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)

      page = 1
      while true
        url = URL + "Year=#{year}&Month=#{month}&Page=#{page}"
        html = connect_to(url:url)&.body
        break if @parser.count_links(html) == 0
        save_file(html, "month_#{month}__page_#{page}", subfolder)
        save_inner_files(html, subfolder, already_fetched)
        page += 1
      end
    end
  end

  def store
    results = []
    already_fetched = UsDeptHca.pluck(:link)
    db_max_date = UsDeptHca.maximum(:date)
    start_date = db_max_date.next_day
    end_date = Date.today
    processed_years = []
    processed_months = []

    (start_date..end_date).each do |date|
      year = date.year
      month = date.month
      next if (processed_years.include? year) && (processed_months.include? month)
      processed_years << year
      processed_months << month

      subfolder = "year_#{year}"
      outer_pages = peon.give_list(subfolder:subfolder).select{|e| e.include? "month_#{month}__page"}
      outer_pages.each do |page|
        content = peon.give(file: page, subfolder: subfolder)
        results = @parser.parser(content, subfolder, already_fetched)
        UsDeptHca.insert_all(results) unless results.empty?
      end
    end
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def save_inner_files(html, subfolder, already_fetched)
    @parser.send_links(html).each do |link|
      file_name = Digest::MD5.hexdigest link
      next if already_fetched.include? file_name
      body = connect_to(url:link)&.body
      save_file(body, file_name, subfolder)
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
end
