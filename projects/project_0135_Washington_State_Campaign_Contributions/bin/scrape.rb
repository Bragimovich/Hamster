# frozen_string_literal: true
require_relative '../lib/wscc_scraper'
require_relative '../lib/wscc_parser'
require_relative '../lib/wscc_run_id'
require_relative '../lib/wscc_database'
require_relative '../lib/wscc_manager'

require_relative '../models/wscc'

def scrape(options)
  if @arguments[:store]
    Scraper.new()
  elsif @arguments[:parse]
    answer = Parser.new()
    p "File doesnt found. Download it (--store)" if answer==1
  elsif @arguments[:parse_new]
    answer = ParserNew.new()
    p "File doesnt found. Download it (--store)" if answer==1
  elsif @arguments[:update]
    answer = WSCCManager.new(**@arguments)
  elsif @arguments[:update_new]
    Scraper.new()
    answer = ParserNew.new()
    p "File doesnt found. Download it (--store)" if answer==1
  else

  end
end
