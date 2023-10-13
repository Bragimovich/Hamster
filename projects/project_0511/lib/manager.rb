# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
  end
  
  def download
    parser = Parser.new(@scraper.link_by)
    @scraper.set_cookie
    google_key = parser.search_google_key
    count = 0
    loop do 
      @scraper.captcha(google_key)
      content = @scraper.send_request(google_key, count)
      break if content.size < 7000
      peon.put(file: "Crime_Data_page_#{count}.html", content: content)
      count += 1
    end
  end

  def store
    peon.give_list.sort.each do |file|
      parser = Parser.new(peon.give(file: file))
      @keeper.data_arr = parser.crime_data
      @keeper.data_arrestees
      @keeper.data_arrests
      @keeper.data_charges
      @keeper.data_bonds
      @keeper.data_mugshots
    end
    @keeper.update_delete_status
    clear
    @keeper.finish
  end

  def clear
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Crime_Data_for_Perps_La_Salle_IL_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end
end
