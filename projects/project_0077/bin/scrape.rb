# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../models/runs'

def scrape(options)
  # place here your code that starting scrape
  # the variable options contains all the command line arguments you can use as Hash

  if( options[:download] )
    Scraper.new(options).download
  elsif options[:parse]
    options.merge!(run_id: Runs.create.id)
    Parser.new(options).parse
  elsif options[:auto]
    scraper = Scraper.new(options)

    begin
      id = Runs.create.id
      scraper.download
      options.merge!(run_id: id)
      Parser.new(options).parse
    rescue StandardError => e

    end

    scraper.delete_file
  end

end
