# frozen_string_literal: true
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @already_inserted_links = @keeper.fetch_already_inserted_links
    @sub_folder = "#{@keeper.run_id}"
  end

  def download
    scraper     = Scraper.new
    links_page  = scraper.connect_to_main_page
    links_array = parser.fetch_all_links(links_page.body)
    save_file(links_page.body, "outer_page", @sub_folder)
    already_downloaded_files = peon.give_list(subfolder: @sub_folder)
    links_array.each do |link|
      next if  @already_inserted_links.include? link
      file_name = Digest::MD5.hexdigest link
      next if already_downloaded_files.include? file_name + ".gz"
      lawyer_page = scraper.connect_to_lawyer_info_page(link)
      save_file(lawyer_page.body,file_name, @sub_folder)
    end
  end

  def store
    hash_array              = []
    already_inserted_hashes = keeper.already_inserted_hashes
    states_array            = @keeper.fetch_us_states
    outer_page              = peon.give(file: "outer_page", subfolder: @sub_folder)
    links_array             = parser.fetch_all_links(outer_page)
    links_array.each do |link|
      next if  @already_inserted_links.include? link
      file_name = Digest::MD5.hexdigest link
      page      = peon.give(file: file_name+".gz", subfolder: @sub_folder)
      data_hash = parser.parser(page, link, states_array, keeper.run_id)
      next if already_inserted_hashes.include? data_hash[:md5_hash]
      hash_array.push(data_hash)
      if hash_array.count > 50
        keeper.save_record(hash_array)
        hash_array = []
      end
    end
    keeper.save_record(hash_array) unless hash_array.empty?
    keeper.mark_deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: @sub_folder
  end
end
