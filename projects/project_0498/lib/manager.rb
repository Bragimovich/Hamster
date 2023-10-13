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
    number  = 1
    loop do
      scraper.link_by(number)
      break unless scraper.page_checked?
      parser = Parser.new(scraper.html)
      parser.nom_list.each do |link|
        scraper.link = link
        pn = scraper.congress_pn
        id = scraper.congress_id
        loop do
          content = scraper.web_page
          if content.status == 200
            peon.put(file: "117_th_Congress_page_#{number}_pn_#{pn}_id_#{id}.html", content: content.body)
            break
          else
            @keeper.data_errors(parser.page_error(content, pn, id))
          end
        end
      end
      number += 1
      break if number > parser.check_page_num
    end
  end

  def store
    peon.give_list.each do |file|
      parser = Parser.new(peon.give(file: file))
      @keeper.data_hash = parser.congress_data(file)
      @keeper.departments_data
      @keeper.committee_data
      @keeper.persons_data
      @keeper.actions_data
      @keeper.nominees_data
    end
    Scraper.new.clear
  end
end
