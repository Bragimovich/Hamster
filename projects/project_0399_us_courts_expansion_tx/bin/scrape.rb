# frozen_string_literal: true

require_relative '../lib/tx_courts'
require_relative '../lib/tx_case_detail'
require_relative '../lib/tx_document_list'
require_relative '../lib/tx_database'
require_relative '../lib/tx_download_pdf'
require_relative '../models/tx_cases'

def scrape(options)
  case options[:step]
  when 'main_first'
    scraper = TXCourtsScrape.new
    scraper.main_first_part(options[:year])

  when 'main_second'
    scraper = TXCourtsScrape.new
    scraper.main_second_part(options[:year].to_s)

  when 'parse_part'
    scraper = TXCourtsScrape.new
    scraper.parse_part(options[:year].to_s)

  when 'download'
    download = TXDownload.new
    download.download_files

  when 'update'
    scrape = TXCourtsScrape.new
    scrape.update(options[:start_date], options[:end_date])

    scraper = CTCourtsScrape.new
    scraper.send(:mark_as_done)

    download = TXDownload.new
    download.download_files
  when 'finish'
    scrape = TXCourtsScrape.new
    scrape.finish(options[:date])

  when 'download'
    download = TXDownload.new
    download.download_files

  when 'mark_as_done'
    scraper = CTCourtsScrape.new
    scraper.send(:mark_as_done)

  when 'rename_files'
    scrape = TXCourtsScrape.new
    scrape.rename_files(options[:year])
  end
end
