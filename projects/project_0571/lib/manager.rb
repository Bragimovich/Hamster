# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @sub_folder = "#{keeper.run_id}"
  end

  def run
    (keeper.download_status == "finish") ? store : download
  end

  def download(retries = 10)
    begin
      downloaded_files = resuming_function
      years_array = (2016..Date.today.year.to_i).map{|e| e unless (downloaded_files.include? e)}.reject(&:nil?)
      scraper = Scraper.new
      scraper.fetch_main_page(storehouse, years_array, sub_folder)
      scraper.close_browser
      keeper.finish_download
      store
    rescue => exception
      raise if retries < 1
      download(retries - 1)
    end
  end

  def store
    files = peon.list(subfolder: "#{sub_folder}")
    files.each do |file|
      file_path = "#{storehouse}store/#{sub_folder}/#{file}"
      year = parser.get_year(file_path)
      db_md5 = keeper.fetch_md5(year)
      data, update_array = parser.get_data(year ,file_path, sub_folder, db_md5)
      keeper.insert_records(data)
      keeper.update_touched_run_id(update_array) unless update_array.empty?
    end
    keeper.mark_delete
    keeper.finish if (keeper.download_status == "finish")
  end

  private
  attr_accessor :keeper, :sub_folder, :parser

  def resuming_function
    peon.list(subfolder: "#{sub_folder}").map{|e| e.gsub('.xlsx','').to_i}.sort rescue []
  end
end
