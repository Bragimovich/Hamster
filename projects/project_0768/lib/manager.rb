# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
require_relative 'connector'
require_relative 'slack_reporter'

require 'fileutils'

class Manager < Hamster::Scraper
  def initialize
    super

    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def run
    clear_file_storage

    page_url = 'https://dchr.dc.gov/public-employee-salary-information'

    html_page = @scraper.get_html_page(page_url)
    pdf_links = @parser.parse_pdf_links(html_page)

    if pdf_links.size.zero?
      logger.info 'No PDF links found in the HTML page.'
      logger.info html_page
      raise "No PDF links found."
    end

    pdf_links.each do |pdf_link|
      as_of_date = pdf_link[0]
      pdf_url    = pdf_link[1]
      file_path  = "#{storehouse}store/#{as_of_date}.pdf"

      logger.info "Downloading PDF - #{as_of_date}"
      logger.info pdf_url
      @scraper.download_pdf_file(pdf_url, file_path)
      logger.info "Download complete"

      @parser.parse_pdf_data(file_path) do |data|
        data.each do |hash|
          hash[:data_source_url] = page_url
          hash[:as_of_date]      = as_of_date

          hire_date = Date.strptime(hash[:hire_date], '%m/%d/%Y').strftime('%Y-%m-%d') rescue nil
          hire_date ||= Date.strptime(hash[:hire_date], '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
          hash[:hire_date] = hire_date

          @keeper.save_data(hash)
        end
      end

      FileUtils::remove_file(file_path, true)
    end

    @keeper.flush
    @keeper.mark_deleted
    @keeper.finish
  end

  private

  def clear_file_storage
    FileUtils.rm_r(Dir.glob("#{storehouse}store/*"))
  end
end
