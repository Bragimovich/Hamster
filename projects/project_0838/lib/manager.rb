# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @run_id = @keeper.run_id
    #@inserted_inmates = @keeper.get_inmates().map{|e| e.split("=").last}
    @sub_folder = "inmates"
  end


  def download
    scraper = Scraper.new
    parser = Parser.new


    ("aa".."zz").each do |latters|

      response = scraper.get_inmates(latters)
      save_file(response, latters , "#{@sub_folder}_page")
      links = parser.get_inmates_links(response.body)
      next if links.empty?

      links.each do |link|

        inmate_no = link.split("=").last
        #next if inserted_inmates.include? inmate_no + ".gz"
        Hamster.logger.debug "CURRENTLY ON ----------> #{inmate_no}"
        response = scraper.get_inmate_details(link)
        save_file(response, inmate_no , "#{@sub_folder}")
      end

    end
  end

  def store
    parser = Parser.new
    keeper = Keeper.new

    ("aa".."zz").each do |latters|

      content_page = peon.give(file: latters+".gz", subfolder: "#{@sub_folder}_page")

      check = parser.get_inmates_links(content_page)
      next if check.empty?

      trs = parser.get_inmates_table(content_page)
      trs.each do |tr|
        data_hash = {}
        id = parser.get_id(tr) + "G.gz"
        file = id

        Hamster.logger.debug "CURRENTLY ON ----------> #{file.gsub(".gz","")}"


        content = peon.give(file: file, subfolder: "#{@sub_folder}")
        data_hash = parser.parse_inmate(content, file, @run_id)
        next if data_hash.empty?
        inmate_id = keeper.insert_inmate(data_hash)

        data_hash = parser.parse_inmate_statuses(inmate_id, tr, @run_id)
        keeper.insert_inmate_statuses(data_hash)

        data_hash = parser.parse_inmate_additional_info(inmate_id, file, content, @run_id)
        keeper.insert_inmate_additional_info(data_hash)

        data_hash = parser.parse_inmate_arrests(inmate_id, file, content, @run_id)
        arrest_id =  keeper.insert_inmate_arrests(data_hash)

        data_array = parser.parse_inmate_arrests_additional(arrest_id, file, content, @run_id)
        keeper.insert_inmate_arrests_additional(data_array) if !data_array.empty?

        data_hash = parser.parse_holding_facilities(arrest_id, file, content, @run_id)
        holding_facility_id = keeper.insert_holding_facilities(data_hash)

        data_hash = parser.parse_holding_facilities_additional(holding_facility_id, file, content, @run_id)
        keeper.insert_holding_facilities_additional(data_hash) if !data_hash.empty?

        data_array = parser.parse_charges(arrest_id, file, content, @run_id)
        if !data_array.empty?
          data_array.each_with_index do |data_hash, ind|

            charge_id = keeper.insert_charges(data_hash)

            data_hash = parser.parse_charges_additional(charge_id, file, content, @run_id, ind)
            keeper.insert_charges_additional(data_hash)

            data_hash = parser.parse_bonds(charge_id, arrest_id, file, content, @run_id, ind)
            keeper.insert_bonds(data_hash)

            data_hash = parser.parse_court_hearings(charge_id, file, content, @run_id)
            keeper.insert_court_hearings(data_hash)
          end
        end
      end

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


