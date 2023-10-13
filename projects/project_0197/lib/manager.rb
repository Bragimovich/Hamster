# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    count = 0
    loop do 
      content_index = @scraper.link_by(count)
      peon.put(file: "press_releases_index_page_#{count}.html",subfolder: "press_releases_index", content: content_index)
      parser = Parser.new(content_index)
      break if parser.next_page == false
      count += 1
    end
  end

  def store
    peon.give_list(subfolder: "press_releases_index").each do |file|
      parser = Parser.new(peon.give(file: file, subfolder: "press_releases_index"))
      parser.press_release_list.each do |hash|
        @scraper.link = hash[:url]
        file_name = Digest::MD5.hexdigest(hash[:url])
        content_page = @scraper.web_page
        parser = Parser.new(content_page)
        article_hash = parser.release_data
        hash.merge!(article: article_hash[:article], with_table: article_hash[:with_table], file: file_name, link: "https://appropriations.house.gov" + hash[:url])
        @keeper.store_release(hash)
        peon.put(file: file_name, subfolder: "press_releases", content: content_page )
      end
    end
    @keeper.update_delete_status
    Scraper.new.clear
    @keeper.finish
  end
end
