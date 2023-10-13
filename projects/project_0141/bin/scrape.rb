# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/store'
require_relative '../models/MidlandCountyCovidCasesDailyRun'
def scrape(options)
  # place here your code that starting scrape
  # the variable options contains all the command line arguments you can use as Hash

  if options[:auto]
    run = MidlandCountyCovidCasesDailyRun.new
    run.status = "download"
    run.save
    arr = Scrape.new(options).run
    run.status="store"
    run.save
    Store.new(run.id).parser(arr)
    run.status="finish"
    run.save
  end

end
