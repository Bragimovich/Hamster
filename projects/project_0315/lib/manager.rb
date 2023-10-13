# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    @sub_folder = "RunID_#{keeper.run_id}"
  end

  def download
    downloaded_files = peon.list(subfolder: sub_folder) rescue []
    main_page = scraper.fetch_page
    save_page(main_page, 'page_1', sub_folder)
    raw_data = parser.fetch_json(main_page.body)
    total_pages = raw_data['page_data']['total_pages']
    last_page = fetch_last_page(downloaded_files)
    pagination(last_page, total_pages)
  end

  def store
    downloaded_files = peon.list(subfolder: sub_folder).sort
    downloaded_files.each do |file|
      content = peon.give(file: file, subfolder: sub_folder)
      raw_data = parser.fetch_json(content)
      hash_array = parser.parse_data(raw_data, keeper.run_id)
      keeper.insert_records(hash_array) unless hash_array.empty?
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper, :sub_folder

  def save_page(body, file_name, sub_folder)
    peon.put content: body.body, file: file_name, subfolder: sub_folder
  end

  def pagination(last_page, total_pages)
    last_page = 2 if last_page == 1
    (last_page..total_pages).each do |page|
      response = scraper.fetch_page(page.to_s)
      next if response.body.empty?

      save_page(response, "page_#{page}", sub_folder)
    end
  end

  def fetch_last_page(downloaded_files)
    downloaded_files.empty? ? 2 : downloaded_files.map { |e| e.split('_').last.gsub('.gz', '').to_i }.max
  end
end
