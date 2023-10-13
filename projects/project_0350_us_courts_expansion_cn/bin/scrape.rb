# frozen_string_literal: true

require_relative '../lib/ct_courts'
require_relative '../lib/ct_case_detail'
require_relative '../lib/ct_document_list'
require_relative '../lib/ct_database'
require_relative '../lib/ct_download_pdf'
require_relative '../models/ct_cases'

def scrape(options)
  case options[:step]
  when 'main_first'
    scraper = CTCourtsScrape.new
    scraper.main_first_part(options[:date], options[:type], options[:end_date])

  when 'main_second'
    scraper = CTCourtsScrape.new
    scraper.main_second_part(options[:date], options[:type])

  when 'parse_part'
    scraper = CTCourtsScrape.new
    scraper.parse_part(options[:date], options[:type])

  when 'rename_files'
    scraper = CTCourtsScrape.new
    scraper.rename_files(options[:type], options[:date])

  when 'download'
    download = CTDownload.new
    download.download_files(options[:type])

  when 'mark_as_done'
    scraper = CTCourtsScrape.new
    scraper.send(:mark_as_done)

  when 'update'
    scraper = CTCourtsScrape.new
    types = %w[Appellate Supreme]
    scraper.update(types, options[:date], options[:end_date])

    scraper.send(:mark_as_done)

    download = CTDownload.new
    download.download_files(options[:type])
  end
end
