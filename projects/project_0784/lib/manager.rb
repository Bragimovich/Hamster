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

  def download
    main_page_response = scraper.main_page_request
    csv_link = parser.get_csv_link(main_page_response)
    csv_response = scraper.csv_request(csv_link)
    saving_file(csv_response.body, 'data', "#{keeper.run_id}", 'csv')
  end

  def store
    file = Dir["#{storehouse}store/#{keeper.run_id}/*.csv"].first
    parser.parse_data(file)
    keeper.mark_delete
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def saving_file(content, file_name, path, type)
    FileUtils.mkdir_p "#{storehouse}store/#{path}/"
    file_storage_path = "#{storehouse}store/#{path}/#{file_name}.#{type}"
    File.open(file_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
