# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../lib/slack_reporter'

require 'fileutils'

class Manager < Hamster::Scraper
  def initialize
    super

    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def run
    years_json = @scraper.get_html_page('https://www.ark.org/dfa/transparency/fiscal_years.php')
    year_links = @parser.parse_fiscal_year_links(years_json)
    raise 'Failed to parse fiscal years.' if year_links.blank?

    year_links.sort_by { |yl| yl[0].to_i }.each do |year_link|
      data_year = year_link[0]
      url = "#{year_link[1].gsub(/\/$/, '')}/employee_compensation.php"

      clear_file_storage

      html_page = @scraper.get_html_page(url)
      down_link = @parser.parse_download_csv_link(html_page)

      file_path = "#{storehouse}store/salaries.csv"
      @scraper.download_csv_file("#{url}#{down_link}", file_path)

      data = @parser.parse_csv_data(file_path)

      data.each do |hash|
        hash[:data_source_url] = url
        hash[:data_year] = data_year
        @keeper.save_data(hash)
      end

      @keeper.flush
    end

    @keeper.mark_deleted
    @keeper.finish

    clear_file_storage
  end

  private

  def clear_file_storage
    FileUtils.rm_r(Dir.glob("#{storehouse}store/*"))
  end
end
