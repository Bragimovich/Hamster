# frozen_string_literal: true


require_relative '../models/gainmi_db_model'

require_relative '../lib/gainmi_lawyer_scraper'
require_relative '../lib/gainmi_lawyer_parser'
require_relative '../lib/gainmi_lawyer_database'
require_relative '../lib/gainmi_lawyer_runs'


STATES = [:georgia, :indiana, :michigan]

def scrape(options)

  if @arguments[:state]
    state = @arguments[:state].to_sym if @arguments[:state].instance_of? String
  end
  if @arguments[:update]
    STATES.each do |state|
      p state
      Scraper.new(state)
    end
  else
    Scraper.new(state)
  end
end
