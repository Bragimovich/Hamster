require_relative '../lib/mechanize_socks'
require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager

  def initialize(options = {})
    return if options.empty?
    @debug = options[:debug]
    @keeper = Keeper.new
    @parse = Parser.new
    @scraper = Scraper.new
  end

  def run
    @scraper.download
    @keeper.year_1 = @scraper.year_1
    @keeper.year_2 = @scraper.year_2
    @keeper.created_by = "Mikhail Golovanov"
    @keeper.data_source = @scraper.data_source
    @keeper.save
  end
end
