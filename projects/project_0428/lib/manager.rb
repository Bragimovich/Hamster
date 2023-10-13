require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'zip'
require 'csv'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    years_array = (2016..(Date.today.year.to_i))
    years_list = keeper.fetch_years
    years_array.each do |year_wise_data|
      next if years_list.include?(year_wise_data)
      last_two_digit = year_wise_data[-2..-1]
      response = scraper.files_downloading(year_wise_data, last_two_digit)
      save_file_zip(response.body, year_wise_data)
    end
    download_county
  end

  def store
    list = peon.list(subfolder: "#{keeper.run_id}")
    years_data = list.select{ |zipfile| zipfile.include? ".zip"}
    data_county_state = source_files(list)
    years_data.each do |each_year_data|
      year = each_year_data.split(".")[0]
      data_array = []
      file_content = unzip_file("#{storehouse}store/#{keeper.run_id}/#{each_year_data}")
      headers = []
      counter = 1
      file_content.split("\n").each_with_index do |data_row, idx|
        if idx == 0
          headers = parser.parse_row(data_row)
          next
        end
        data_value = parser.parse_row(data_row)
        next if data_value[0].start_with?("00")
        hash_data = parser.get_data(data_row, idx, headers, data_value)
        parser.county_state(data_county_state, hash_data, keeper.run_id, year)
        data_array << hash_data
        if data_array.count == 5000
          keeper.insertion(data_array) unless data_array.empty?
          data_array = []
        end
      end
      keeper.insertion(data_array) unless data_array.empty?
    end
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser, :scraper

  def download_county
    list = peon.list(subfolder: "#{keeper.run_id}")
    unless list.empty?
      state_county_file = list.select{ |txtfile| txtfile.include? "county_state"}
      if state_county_file.empty?
        county_state_file = scraper.county_state()
        save_county_state(county_state_file.body, "county_state")
      end
    end
  end

  def source_files(list)
    state_county_file = list.select{ |txtfile| txtfile.include? "county_state"}
    data_county_state = []
    file_data = File.open("#{storehouse}store/#{keeper.run_id}/#{state_county_file[0]}")
    data_county_state = file_data.readlines.map(&:chomp)
    data_county_state
  end

  def save_file_zip(zip_file, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.zip"
    File.open(zip_storage_path, "wb") do |f|
      f.write(zip_file)
    end
  end

  def save_county_state(county_state_file, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    text_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.txt"
    File.open(text_storage_path, "wb") do |f|
      f.write(county_state_file)
    end
  end

  def unzip_file(file_name)
    content = nil
    zip_file = Zip::File.open("#{file_name}")
    zip_file.first.get_input_stream { |io|
      content = io.read
    }
    content
  end
end
