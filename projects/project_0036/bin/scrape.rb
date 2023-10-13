# frozen_string_literal: true

require_relative '../lib/us_patents_scraper'
require_relative '../lib/us_patents_parser'
require_relative '../models/us_patent'

SCRAPE_NAME = '#36 US Patents'

def scrape(options)
  begin
    list = options[:list]
    continue = options[:c] || options[:continue] ? true : false
    period = options[:period]
    where_proxy = options[:where_proxy]
    case
    when options[:s] || options[:scrape]
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting scrape...", use: :both)
      puts "PERIOD: #{period}"
      if period == 'week'
        ((get_recent_issue_date + 1)...(Date.today)).each do |date|
          report(to: 'sergii.butrymenko', message: "YEAR:  #{date.year}\nMONTH: #{date.month}\nDAY:   #{date.day}", use: :both)
          scraping(date.year, date.month.to_s.rjust(2, '0'), date.day.to_s.rjust(2, '0'), continue, list, where_proxy)
        end
      else
        year, month, day = init(options)
        report(to: 'sergii.butrymenko', message: "YEAR:  #{year}\nMONTH: #{month}\nDAY:   #{day}", use: :both)
        scraping(year, month, day, continue, list, where_proxy)
      end
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Scraping is done!", use: :both)

    when options[:p] || options[:parse]
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting parse...", use: :both)
      parsing
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Parsing is done!", use: :both)
      # pr = AlabamaBusinessLicensesParser.new
      # pr.parse
    when options[:sp] || options[:scrape_parse]
      year, month, day = init(options)
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting scrape & parse...", use: :both)
      scraper = Thread.new { scraping(year, month, day, continue, list, where_proxy) }
      report(to: 'sergii.butrymenko', message: "YEAR:  #{year}\nMONTH: #{month}\nDAY:   #{day}", use: :both)
      parser  = Thread.new { sleep 10 *60; parsing }
      scraper.join
      parser.join
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Scraping & parsing are done!", use: :both)
    else
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Trying to run without mode specified. Exiting...", use: :both)
      exit 1
    end
    0
  rescue StandardError => e
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: ERROR", use: :both)
    report(to: 'sergii.butrymenko', message: "#{e} | #{e.backtrace}")
  end
end

private

def init(options)
  if options[:year].nil?
    date = get_recent_issue_date.next_month
    year = date.year.to_s
    month = date.month.to_s.rjust(2, '0')
    day = '$'
  else
    year = options[:year].to_s
    month = options[:month].nil? ? '$' : options[:month].to_s.rjust(2, '0')
    day = options[:day].nil? ? '$' : options[:day].to_s.rjust(2, '0')
  end
  [year, month, day]
end

def scraping(year, month, day, continue, list, where_proxy)
  sc = USPatentsScraper.new
  sc.scrape(year, month, day, continue, list, where_proxy)
end

def parsing
  pr = USPatentsParser.new
  pr.parse
  # report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting tables copying...", use: :both)
  # pr.move_to_general_tables
end

def get_recent_issue_date
  USPatent.maximum(:issue_date)
end
