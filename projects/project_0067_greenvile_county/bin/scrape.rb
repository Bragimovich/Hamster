# frozen_string_literal: true

require_relative '../lib/greenville_scraper'
require_relative '../lib/greenville_parser'
require_relative '../lib/greenville_database'

def scrape(options)
  parse_arguments
  today = Date.today()
  if @arguments[:download_date]
    if @arguments[:download_date].class==Integer
      Scraper.new(@arguments[:download_date])
    elsif @arguments[:download_date].class==String
      o = 0
      begin
        year, month, day = @arguments[:download_date].split('-')
        Scraper.new(year.to_i, month.to_i, day.to_i, @arguments[:general])
      rescue => e
        Hamster.logger.error e
        o+=1
        Hamster.logger.error "Retry №#{o}"
        retry if o<6
      end
    else
      Scraper.new(2021)
    end
  elsif @arguments[:check]
    check_parser

    #_________BEGIN__FOR__LAUNCHER _______
  elsif @arguments[:download]
    date_check = Date.today() - 7
    Scraper.new(date_check.year, date_check.month, date_check.day, true)
    Scraper.new(date_check.year, date_check.month, date_check.day, false)
    return 0
  elsif @arguments[:store]
      PutInDb.new(2020)
      PutInDb.new(2019)
      PutInDb.new(2018)
      PutInDb.new(2017)
      PutInDb.new(2016)
      PutInDb.new(2021)
      PutInDb.new(2021, 1)
      PutInDb.new(2022)
      PutInDb.new(2022, 1)
      return 0
  #__________END__FOR__LAUNCHER________
  elsif @arguments[:parse]
    if @arguments[:parse]=='all'
      PutInDb.new(2020)
      PutInDb.new(2019)
      PutInDb.new(2018)
      PutInDb.new(2017)
      PutInDb.new(2016)
      PutInDb.new(2021)
      PutInDb.new(2022)
      PutInDb.new(today.year)
    else
      PutInDb.new(2021)
      PutInDb.new(2021, 1)
      PutInDb.new(2022)
      PutInDb.new(2022, 1)
      PutInDb.new(today.year)
    end
  elsif @arguments[:update]
    if @arguments[:update]!=true
      days = @arguments[:update]-7
    else
      days = 0
    end
    date_check = today - 7 - days
    Hamster.logger.debug date_check


    begin
      Hamster.logger.debug 'case filled'
      Scraper.new(date_check.year, date_check.month, date_check.day, true)
      Scraper.new(date_check.year, date_check.month, date_check.day, false)
      PutInDb.new(date_check.year)
    end

    o = 0
    begin
      Hamster.logger.debug 'disposed'
      Scraper.new(date_check.year, date_check.month, date_check.day, true, 1)
      Hamster.logger.info 'disposed'
      Scraper.new(date_check.year, date_check.month, date_check.day, false, 1)
    rescue => e
      Hamster.logger.info e
      o+=1
      Hamster.logger.info "Retry №#{o}"
      retry if o<6
    end
    o = 0
    begin
      Hamster.logger.info 'activities date'
      Scraper.new(date_check.year, date_check.month, date_check.day, true, 2)
      Hamster.logger.info 'activities date'
      Scraper.new(date_check.year, date_check.month, date_check.day, false, 2)
    rescue => e
      Hamster.logger.debug e
      o+=1
      Hamster.logger.debug "Retry №#{o}"
      retry if o<6
    end

    Hamster.logger.info 'put all in db'
    PutInDb.new(date_check.year, 1)
    #PutInDb.new(date_check.year+1, 1)
  elsif @arguments[:test]
    Hamster.logger.debug 'test'
    file = File.open("").read
    q = Parser.new(file)
  end





end
