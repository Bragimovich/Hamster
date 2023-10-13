# frozen_string_literal: true

require_relative '../lib/rh_embassy'

def scrape(options)
  #config = options[:config] || 'site_config_us_secret_service'
  Embassy.new()
  #scr = Hamster::Scraper.new()

  # if @arguments[:config]
  #   config = @arguments[:config]
  # else
  #   #config = 'site_config_dept_of_transport'
  #   #config = 'site_config_fcc'
  #   #config = 'site_config_dept_energy'
  #   config = 'site_config_us_secret_service'
  # end

  #scr.robohamster("../configs/#{config}.yml")
end



