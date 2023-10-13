# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @sub_folder = "RunID_#{keeper.run_id}"
  end

  def download
    scraper = Scraper.new
    landing_page = scraper.fetch_main_page
    @alphabet_array = ('aaa'..'zzz').map(&:to_s)
    @alphabet_array[get_starting_index..-1].each do |letters|
      response = scraper.search_request(letters)
      save_file(response, letters, "#{sub_folder}")
    end
  end

  def store
    parser = Parser.new
    downloaded_files = peon.list(subfolder: sub_folder)
    downloaded_files.each do |file|
      file = peon.give(file: file, subfolder: sub_folder)
      hash_array = parser.process_file(file, keeper.run_id)
      keeper.insert_records(hash_array) unless hash_array.empty?
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :sub_folder

  def get_starting_index
    latest_file = peon.list(subfolder: sub_folder).sort.max.gsub('.gz','') rescue []
    unless latest_file.empty?
      return (@alphabet_array.index latest_file)
    end
    0
  end

  def save_file(body, file_name, sub_folder)
    peon.put content: body.body, file: file_name, subfolder: sub_folder
  end
end
