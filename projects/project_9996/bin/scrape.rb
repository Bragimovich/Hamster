# frozen_string_literal: true
require_relative '../models/us_case_pdf_on_aws'
require_relative '../models/us_courts_case_summary_files'
require_relative '../models/us_courts_case_summary_court_links'
require_relative '../lib/scraper'

def scrape(options)
  begin
    if options[:download]
    kit = NYCourtsCaseSummaryPDF.new
    kit.transfer_ny_courts_case_summary_to_pdf(options[:court_ids])
    end
  rescue => e
    puts "#{e} | #{e.backtrace}"
  end
end


