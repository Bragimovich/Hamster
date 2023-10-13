# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @keeper = Keeper.new
  end
  
  def download
    p "Download start"
    generate_session
    cities = @scraper.get_cities
    cities.each do |city|
      get_data_by_city(city)
    end
    @keeper.finish
    p "Download ended"
  end

  private

  def get_data_by_city(city)
    generate_session if @limit == 10
    list = @scraper.get_data_by_city(city)
    @limit += 1
    
    length = list.size

    for i in 0..length - 1
      if @limit == 10
        generate_session
        list = @scraper.get_data_by_city(city)
        @limit += 1
      end

      data = @scraper.get_offender(list[i]['FCN'])
      @limit += 1
      @keeper.save(data) unless data['FirstName'].nil?
    end
  end

  def generate_session
    @scraper.generate_session
    @limit = 0
  end
end