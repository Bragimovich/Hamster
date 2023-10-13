# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def download
    scraper = Scraper.new
    row_start = 0
    page = 1
    while true
      response = scraper.main_request(row_start)
      save_file("#{keeper.run_id}", response.body, "file_#{page}.json")
      break if parser.json_response(response.body).empty?
      page += 1
      row_start += 100
    end
  end

  def store
    json_files = peon.give_list(subfolder: "#{keeper.run_id}")
    json_files.each do |file|
      file_data = peon.give(subfolder: "#{keeper.run_id}", file: file)
      data_array = parser.file_process(file_data , "#{keeper.run_id}")
      keeper.insert_records(data_array)
    end
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

end
