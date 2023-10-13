# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Georgia_Parser.new
    @keeper = Keeper.new
    @alphabet_array = ('aa'..'zz').map(&:to_s)
  end

  def download(retries = 15)
    begin
      (get_starting_index == 0) ? start_index = 0 : start_index = get_starting_index + 1
      scraper = Georgia_scraper.new
      @alphabet_array[start_index..-1].each do |letters|
        downloaded_gdc = fetch_downloaded_gdcs
        puts "Processing => #{letters}"
        available_records = scraper.fetch_html(letters.first,letters.last)
        available_records = available_records.reject{|e| downloaded_gdc.include? e[:gdc_id]}
        make_empty_folder(letters) if (available_records.empty?)
        available_records.each do |record|
          save_page(record[:html], record[:gdc_id],"#{keeper.run_id}/#{letters}")
        end
      end
    rescue
      scraper.close_browser
      raise if retries < 1
      download(retries - 1)
    end
  end

  def store
    md5_offender = keeper.already_inserted_md5('offenders')
    md5_offenses = keeper.already_inserted_md5('offenses')
    downloaded_folders = peon.list(subfolder: "#{keeper.run_id}/")
    downloaded_folders.each do |folder|
      puts "Processing ==>#{folder}"
      downloaded_files = peon.give_list(subfolder: "#{keeper.run_id}/#{folder}")
      downloaded_files.each do |file|
        body = peon.give(subfolder: "#{keeper.run_id}/#{folder}",file: file)
        data_array,sentences_array = parser.parse_data(body,keeper.run_id,md5_offender,md5_offenses)
        keeper.insert_records(data_array,'offenders')
        keeper.insert_records(sentences_array,'offenses')
      end
    end
    keeper.mark_delete('offenders')
    keeper.finish
  end

  private

  attr_reader :keeper,:parser

  def make_empty_folder(letters)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/#{letters}"
  end

  def fetch_downloaded_gdcs
    already_downloaded_pages = []
    all_folders = peon.list(subfolder: "#{keeper.run_id}/") rescue []
    all_folders.each do |folder|
      already_downloaded_pages << peon.give_list(subfolder: "#{keeper.run_id}/#{folder}").map{|file| file.to_s.split('.').first}
    end
    already_downloaded_pages.flatten.uniq
  end

  def get_starting_index
    latest_file = peon.list(subfolder: "#{keeper.run_id}/").sort.max rescue []
    unless latest_file.empty?
      return (@alphabet_array.index latest_file)
    end
    0
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end

end
