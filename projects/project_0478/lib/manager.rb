# frozen_string_literal: true

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
    number  = fail_check.nil? ? 1 : fail_check
    loop do
      scraper.link_by(number)
      break unless scraper.page_checked?
      parser = Parser.new(scraper.html)
      parser.lawyers_list.each do |link|
        scraper.link = link
        retries = 0
        begin
          content = scraper.web_page
          unless content.nil?
            peon.put(file: "lawyer_#{number}_#{scraper.lawyer_id}.html", content: content)
            parser = Parser.new(content)
            @keeper.store_data(parser.lawyer_data)
          end
        rescue => e
          @logger.debug(e.full_message)
          @logger.debug(retries += 1)
          retry if retries < 5
        end
      end
      number += 1
    end
    @keeper.update_delete_status
    scraper.clear
    @keeper.finish
  end

  def store
    peon.give_list.each do |file|
      parser = Parser.new(peon.give(file: file))
      @keeper.store_data(parser.lawyer_data)
    end
    @keeper.update_delete_status
    Scraper.new.clear
    @keeper.finish
  end

  private
  
  def fail_check
    files = peon.give_list
    return if files.empty?
    failed_at = files.sort.last.split('.').first.split('_')[-2]
    failed_at.first.to_i
  end
end
