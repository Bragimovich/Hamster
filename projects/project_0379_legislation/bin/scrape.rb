# frozen_string_literal: true

require_relative '../lib/legislation_scraper'
require_relative '../lib/legislation_parser'
require_relative '../models/congressional_legislation'

require_relative '../lib/legislation_keeper'

require_relative '../lib/legislation_match'



def scrape(options)
  LegislationMatcher.new() if options[:match]

  Scraper.new(update = options[:update], work = options[:work]) if !options[:match]
  # place here your code that starting scrape
  # the variable options contains all the command line arguments you can use as Hash
  #
  #test_par

end


def test_par
  #file = 'projects/project_0379/lib/test/H.R.5999.html'
  #q = '../lib/test/H.R.6198.html'
  file = 'projects/project_0379_legislation/lib/test/H.R.6000.html'
  html_page = ''
  File.open(file, 'r') { |file| html_page=file.read}
  parser = ParserOnePage.new()
  p parser.parse_article_page(html_page)[:subjects]

end