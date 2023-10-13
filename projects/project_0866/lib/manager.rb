# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @run_id = @keeper.run_id
  end


  def download
    scraper = Scraper.new
    parser = Parser.new

    response = scraper.fetch_main_page
    links = parser.get_links(response.body)

    links.each do |link|

      year = link.match(/\d{4}/)[0]
      extension = link.split(".").last
      Hamster.logger.debug "CURRENTLY ON ----------> #{year}"
      response = scraper.download_file(link)

      path = "#{storehouse}store/#{year}.#{extension}"
      save_file(response, path)
    end
  end

  def store
    parser = Parser.new
    keeper = Keeper.new
    files = peon.list().delete_if { |x| x == ".DS_Store" }
    files.each do |file|

      Hamster.logger.debug "CURRENTLY ON ----------> #{file}"
      path =  "#{storehouse}store/#{file}"
      data_array = parser.parse_file(path, @run_id)

      keeper.insert_file(data_array)
 
    end

    keeper.finish
  end


  private

  attr_accessor :keeper



  def save_file(response, save_path)

    File.open(save_path, 'wb') do |file|
      file.write(response.body)
    end
  end

end


