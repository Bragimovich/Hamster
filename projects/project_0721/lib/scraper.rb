# frozen_string_literal: true

require_relative 'parser'
class Scraper < Hamster::Scraper
  START_PAGE      = 'https://www.azed.gov/esa'

  def initialize
    @parser    = Parser.new
    @connector = Dasher.new(url: START_PAGE, using: :cobble, pc: 1)
  end

  def scrape(&block)
    raise 'Block must be given' unless block_given?

    response = @connector.get(START_PAGE)
    pdf_list = @parser.pdf_urls_from(response)
    pdf_list.each(&block)
  end
end
