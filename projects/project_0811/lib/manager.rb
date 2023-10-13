# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @run_id = keeper.run_id
    @sub_folder = "inmates"
  end


  def download
    scraper = Scraper.new
    parser = Parser.new

    response = scraper.get_search_inmates
    inmates_links = parser.get_inmates_links(response)
    #inmate_files = peon.list(subfolder: sub_folder).delete_if { |x| x == ".DS_Store" }

    inmates_links.each do |link|

      inmate_no = link.split("=").last
      #next if inmate_files.include? inmate_no + ".gz"
      Hamster.logger.debug "CURRENTLY ON ----------> #{inmate_no}"
      response = scraper.get_inmate_detail(link)
      save_file(response, inmate_no , @sub_folder)
    end
  end

  def store
    parser = Parser.new

    inmate_files = peon.list(subfolder: sub_folder).delete_if { |x| x == ".DS_Store" }
    inmate_files.each do |file|
      data_hash = {}

      #next if  @inserted_inmates.include? file.gsub(".gz", "")
      Hamster.logger.debug "CURRENTLY ON ----------> #{file.gsub(".gz","")}"
      content = peon.give(file: file, subfolder: sub_folder)

      data_hash = parser.parse_inmate(file, content, @run_id)
      next if data_hash.empty?
      inmate_id = keeper.insert_inmate(data_hash)
      data_hash = parser.parse_inmate_ids(inmate_id, file, content, @run_id)
      keeper.insert_inmate_ids(data_hash)
      data_hash = parser.parse_inmate_additional_info(inmate_id, file, content, @run_id)
      keeper.insert_inmate_additional_info(data_hash)
      data_hash = parser.parse_statuses(inmate_id, file, content, @run_id)
      keeper.insert_statuses(data_hash)
      data_hash = parser.parser_arrests(inmate_id, file, content, @run_id)
      arrest_id = keeper.insert_arrests(data_hash)
      data_hash = parser.parse_arrests_additional(arrest_id, file, content, @run_id)
      keeper.insert_arrests_additional(data_hash)
      data_hash = parser.parse_charges(arrest_id, file, content, @run_id)
      charge_id = keeper.insert_charges(data_hash)
      data_hash = parser.parse_bonds(charge_id, arrest_id, file, content, @run_id)
      keeper.insert_bonds(data_hash)
      data_hash = parser.parse_court_hearings(charge_id, file, content, @run_id)
      keeper.insert_court_hearings(data_hash)
      data_hash = parser.parse_holding_facilities(arrest_id, file, content, @run_id)
      keeper.insert_holding_facilities(data_hash)
      data_hash = parser.parse_parole_booking_dates(inmate_id, file, content, @run_id)
      keeper.insert_parole_booking_dates(data_hash) if !data_hash.empty?

    end
    keeper.finish
  end


  private

  attr_accessor :keeper, :sub_folder

  def get_content(file)
    peon.give(file: file)
  end


  def save_pdf(content, file_name, sub_folder)
    pdf_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(response, file_name , sub_folder)
    peon.put content: response.body, file: file_name, subfolder: sub_folder
  end

end
