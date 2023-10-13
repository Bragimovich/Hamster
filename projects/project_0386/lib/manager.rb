# frozen_string_literal: true

require_relative '../lib/connect'
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end

  def download
    scraper = Scraper.new
    ('a'..'z').each do |char_name|
      num = 1
      count = 0
      loop do
        scraper.link_by(char_name, num)
        if scraper.page_checked?
          parser = Parser.new(scraper.html)
          parser.lawyers_list.each do |link|
            scraper.link = link[:url]
            content = scraper.web_page
            if content.size < 500
              count += 1
              redo if count < 6
              count = 0
            else
              peon.put(file: "or_osbar_bar_#{scraper.lawyer_bar}_city-#{link[:city]}.html", content: content )
            end
          end
        else
          bar = scraper.html.split.last.split("&amp").first.split("=").last
          if scraper.check_bar_n?(bar)
            parser = Parser.new(scraper.bar_n_html)
            peon.put(file: "or_osbar_bar_#{bar}_city-not_determined.html", content: scraper.bar_n_html)
          else
            break
          end
        end
        num +=1
      end
    end
  end

  def store
    peon.give_list.each do |file|
      city = file.split('-')[-1].split('.')[0]
      city.size == 0 ? nil : city
      parser = Parser.new(peon.give(file: file))
      @keeper.store_data(parser.lawyer_data(city))
      clear(file)
    end
    @keeper.update_delete_status
    @keeper.finish
  end

  def clear(file)
    trash_folder = "or_osbar_trash"
    peon.move(file: file, to: trash_folder)
  end
end
