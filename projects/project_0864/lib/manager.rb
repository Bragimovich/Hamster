# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def download(retries = 10)
    begin
      scraper.download_pages
    rescue
      scraper.close_browser
      raise if (retries < 1)
      download(retries - 1)
    end
  end

  def store
    files = peon.list(subfolder: "#{keeper.run_id}").reject{ |e| e.include? 'txt'}
    files.each do |file|
      page_body = peon.give(subfolder: "#{keeper.run_id}", file: file)
      data_array,md5_array = parser.parse_data(page_body, keeper.run_id)
      keeper.insert_records(data_array)
      keeper.update_touched_run_id(md5_array)
    end
    keeper.mark_delete
    keeper.finish
    FileUtils.rm_rf("#{storehouse}store/#{keeper.run_id}")
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

end
