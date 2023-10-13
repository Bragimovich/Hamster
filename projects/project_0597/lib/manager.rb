# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
    @parser = Parser.new
    @sub_folder = "RunId_#{keeper.run_id}"
  end

  def download
    starting_index, downloaded_folders = resuming
    years_array[starting_index..-1].each_with_index do |year, index|
      response = scraper.get_departments(year)
      dat = parser.parse_json(response.body)
      all_departments = dat["records"].map{|e| e["label"]}.reject(&:nil?)
      all_departments[st_ind..-1].each do |department|
        offset = 0
        while true
          response = scraper.api_call(offset, year, department)
          data = parser.parse_json(response.body)
          break if data["records"].count == 0
          save_page(response.body, "Page_#{offset.to_s}", "#{sub_folder}/#{year.to_s}/#{department.scan(/\w+/).join}")
          offset += 5000
        end
      end
    end
  end

  def store
    all_years = peon.list(subfolder: sub_folder)
    all_years.each do |year|
      all_departments = peon.list(subfolder: "#{sub_folder}/#{year}")
      all_departments.each do |department|
        all_files = peon.list(subfolder: "#{sub_folder}/#{year}/#{department}")
        all_files.each do |file|
          response = peon.give(file: file, subfolder: "#{sub_folder}/#{year}/#{department}")
          data = parser.parse_json(response)
          hash_array = parser.parse(data, year, keeper.run_id, department)
          keeper.insert_records(hash_array)
        end
      end
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper, :sub_folder

  def years_array
    ((Date.today.year-8)..(Date.today.year)).map(&:to_i)
  end

  def resuming
    max_folder = peon.list(subfolder: sub_folder).sort.max rescue nil
    return [0, 0] if max_folder.nil?
    downloaded_folders = peon.list(subfolder: "#{sub_folder}/#{max_folder}")
    [(years_array.index max_folder.to_i), downloaded_folders]
  end

  def save_page(html, file_name, subfolder)
    peon.put content: html, file: "#{file_name}", subfolder: subfolder
  end
end
