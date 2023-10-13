# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end
  
  def download
    scraper = Scraper.new
    peon.put(file: "Crime_Data_#{Time.now.strftime("%Y-%m-%d")}.html", content: scraper.link_by)
  end

  def store
    peon.give_list.each do |file|
      parser = Parser.new(peon.give(file: file))
      @keeper.data_arr = parser.crime_data
      @keeper.data_arrestees
      @keeper.arrestee_ids
      @keeper.data_arrests
      @keeper.data_charges
    end
    @keeper.update_delete_status
    Scraper.new.clear
    @keeper.finish
  end
end
