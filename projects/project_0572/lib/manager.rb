# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def download
    scraper = Scraper.new
    response = scraper.get_csv_response
    save_csv(response.body)
  end

  def store
    csv_files = Dir["#{storehouse}store/#{keeper.run_id}/*.csv"]
    csv_files.each do |file|
      data_array = parser.parse_data(file, keeper.run_id)
      keeper.insert_records(data_array)
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def save_csv(content)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/Data.csv"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
