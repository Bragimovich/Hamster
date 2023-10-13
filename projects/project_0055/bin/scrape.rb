# frozen_string_literal: true

def scrape(options)
  if options[:download]
    PacerScraper.new(options[:grab]).start
  elsif options[:store]
    PacerHTMLPages.new(options[:grab]).start
  end
end
