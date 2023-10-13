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
    url = "https://www.maine.gov/doe/sites/maine.gov.doe/files/bulk/tableau/TABLEAU_ESEA_data_download.xlsx"
    scraper.connect_to(url, method: :get_file, filename: storehouse+"store/" + "data.xlsx")
  end

  def store
    insert_general_info_data
    ids_and_numbers = keeper.pluck_ids_numbers_without_district
    ids_and_numbers_with_district = keeper.pluck_ids_numbers_with_district
    parser.initialize_values(ids_and_numbers, ids_and_numbers_with_district, 1)
    store_enrollment_files
    store_graduation_files
    store_assessment_files
    store_finance_sheet
    store_perfomance_indicator
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def insert_general_info_data
    district_table_data = keeper.pluck_district_table_data
    keeper.insert_general_info_data(district_table_data, 1)
    school_table_data = keeper.pluck_school_table_data
    keeper.insert_school_data(school_table_data, 1)
  end

  def store_graduation_files
    file = get_files
    data_array = parser.parse_graduation_data(file.first)
    keeper.insert_records(data_array, 'me_graduation')
  end

  def store_assessment_files
    file = get_files
    data_array = parser.parse_assesement_data(file.first)
    byebug
    keeper.insert_records(data_array, 'me_assessment')
  end

  def store_enrollment_files
    file = get_files
    data_array = parser.parse_enrollment_data(file.first)
    keeper.insert_records(data_array, 'me_enrollment')
  end

  def store_finance_sheet
    file = get_files
    data_array = parser.parse_finance_data(file.first)
    keeper.insert_records(data_array, 'me_finance')
  end

  def store_perfomance_indicator
    file = get_files
    data_array = parser.perfomance_indicator(file.first)
    keeper.insert_records(data_array, 'me_performance indicator')
  end

  def get_files(folder=nil, file_type=nil)
    Dir["#{storehouse}store/data.xlsx"]
  end

end
