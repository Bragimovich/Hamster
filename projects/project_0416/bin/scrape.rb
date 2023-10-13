# frozen_string_literal: true
require_relative '../lib/end_of_year_student_discipline_report_scraper'
require_relative '../lib/end_of_year_student_discipline_report_parser'
require_relative '../models/il_school_suspension'

SCRAPE_NAME = '#416 End of Year Student Discipline Report'

def scrape(options)
  begin
    academic_year = options[:academic_year]
    case
    when options[:s] || options[:scrape]
      report_me('START')
      scraping(academic_year)
    when options[:p] || options[:parse]
      parsing
    when options[:sp] || options[:scrape_parse]
      scraping(academic_year)
      parsing
    else
      report_me("Missing mode specification. Exiting...")
    end
  rescue StandardError => e
    report_me("*ERROR*")
    report_me("#{e} | #{e.backtrace}")
  end
end

def report_me(message)
  report(to: 'sergii.butrymenko',
         message: "Scrape *#416 End of Year Student Discipline Report*\n>#{message}",
         use: :both)
end

def scraping(academic_year)
  report_me 'Scraping started'
  sc = EndOfYearStudentDisciplineReportScraper.new
  sc.scrape(academic_year)
  report_me 'Scraping finished successfully'
end

def parsing
  report_me 'Parsing started'
  pr = EndOfYearStudentDisciplineReportParser.new
  pr.parse
  # report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting tables copying...", use: :both)
  # pr.move_to_general_tables
  report_me 'Parsing finished successfully'
end
