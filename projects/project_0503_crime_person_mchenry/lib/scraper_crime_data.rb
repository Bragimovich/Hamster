# frozen_string_literal: true

require 'date'
require 'json'
require 'net/http'
require 'logger'


class ScraperCrimeData < Hamster::Scraper
  BASE_URL = 'https://www.mchenrysheriff.org/corrections/corrections-information'
  attr_writer :link

  def initialize
    super
    # @keeper = Keeper.new
  end

  def link_by
    @result = connect_
  end

  def page_checked?
    @result = connect_to(@link)
    @result.status == 200
  end

  def content
    @result.body
  end

  def web_page
    web = "https://guambar.org#{@link}"
    res = connect_to(web)
    res.body
  end

  def lawyer_id
    @link.split('/').last
  end

  def clear
    trash_folder = 'guambar_org'
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def connect_
    Net::HTTP.start('www.mchenrysheriff.org') do |http|
      http.get('/wp-content/uploads/pdf-uploads/InmateSearch_ByDate.pdf')
    end
  rescue SystemExit, Interrupt, StandardError => e
    puts '--------------------------------------'
    puts e.backtrace.join("\n")
  end

end
