# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
require_relative 'connector'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def scrape
    opinions = []
    (2018..Date.today.year).each do |year|
      scraper = Scraper.new(year)
      scraper.scrape do |opinion|
        opinions << opinion
      end
      @keeper.add_records(opinions)
      opinions = []
    end
    @keeper.update_history
    @keeper.finish
  end
end
