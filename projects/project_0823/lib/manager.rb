# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @parser = Parser.new
  end

  def store
    file = Dir["#{storehouse}store/**/*.txt"].reject{ |e| e.include? 'processed' }
    parser.parse_data(file.first)
    keeper.mark_delete
    keeper.finish
  end

  private

  attr_accessor :parser, :scraper

end
