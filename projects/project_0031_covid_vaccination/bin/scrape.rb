# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'

# LOGFILE = "../logfile.log"

def scrape(options)
  # File.open(LOGFILE, 'a') do |file|
  #   file.puts Time.now.to_s
  # end

  task = options['do']

  if ['s', 'scrape'].include? task
    Scraper.new.main
  elsif ['p', 'parse'].include? task
    Parser.new.main
  elsif ['s&p', 'scrape&parse'].include? task

    Scraper.new.main
    Parser.new.main

  end
end
