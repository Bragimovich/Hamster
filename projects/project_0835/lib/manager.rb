require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
require_relative '../models/mi_wayne_runs'
require 'open-uri'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @peon = Peon.new(storehouse)
    @run_object = RunId.new(MiWayneRuns)
    @run_id = @run_object.run_id
  end

  FILENAME = 'full_list'
  
  def download
    ('a'..'z').each do |letter|
      response = @scraper.fetch_main_page
      doc = Nokogiri::HTML(response.body)
      logger.debug ('*'*100).green
      @input_value = letter
      logger.debug letter.green
      logger.debug ('*'*100).green
      response = @scraper.search_request(@input_value)
      doc = Nokogiri::HTML(response.body)
      if doc.css("select[name='Page']").text.empty? == true 
        pages = []
        pages << 1
      else
        pages = doc.css("select[name='Page']").text.squish.split("of")[-1].strip.split
      end 
      pages.each do |page|
        url = "http://50.239.65.109/NewWorld.InmateInquiry/MI8218200?Name=#{letter}&SubjectNumber=&BookingNumber=&BookingFromDate=&BookingToDate=&InCustody=&Page=#{page}"
        current_page_html = @scraper.current_page_html(url)
        today_string = Date.today.to_s.gsub("-", "_")
        current_page_file_name = "#{FILENAME}_page_#{page}_for_#{today_string}"
        sub_folder = "sub_folder_for_page_#{page}"
        @peon.put(content: current_page_html.body, file: current_page_file_name, sub_folder: sub_folder)
        inmates = @parser.current_page(current_page_html)
        existed_inmate_files = @peon.give_list()
        inmates.each do |booking_id, inmate|
          booking_id = booking_id.gsub("/","_")
          next if existed_inmate_files.include? ("#{booking_id}.gz")
          inmate_page_html = @scraper.inmate_page(inmate[:link])
          @peon.put(content: inmate_page_html.body, file: booking_id)
          logger.debug "#{inmate} file added".green
        end
      end
    end

  end

  def store
    ('a'..'z').each do |letter|
      response = @scraper.fetch_main_page
      doc = Nokogiri::HTML(response.body)
      @input_value = letter
      response = @scraper.search_request(@input_value)
      doc = Nokogiri::HTML(response.body)
      pages = doc.css("select[name='Page']").text.squish.split("of")[-1].strip.split
      pages.each do |page|
        today_string = Date.today.to_s.gsub("-", "_")
        current_page_file_name = "#{FILENAME}_page_#{page}_for_#{today_string}"
        current_page_html = @peon.give(file: current_page_file_name)
        return "FILE for #{today_string} is not exist" if current_page_html.nil?
  
        @md5_hash_maker = {
          :arrests => MD5Hash.new(columns: [:inmate_id, :booking_number, :booking_date, :data_source_url]),
          :bonds => MD5Hash.new(columns: [:arrest_id, :bond_number, :bond_type, :bond_amount, :total_bond_amount, :data_source_url]),
          :charge => MD5Hash.new(columns: [:arrest_id, :charge_number, :disposition, :offense_date, :docket_number, :crime_class, :data_source_url]),
          :county_court_hearings => MD5Hash.new(columns: [:charge_id, :court_date, :sentence_lenght, :data_source_url]),
          :county_holding_facilities => MD5Hash.new(columns: [:arrest_id, :facility, :data_source_url]),
          :inmate_ids => MD5Hash.new(columns: [:inmate_id, :arrestee_id, :data_source_url]),
          :inmates => MD5Hash.new(columns: [:name, :first_name, :middle_name, :last_name, :birthdate, :date_source_url]),
          :mugshots => MD5Hash.new(columns: [:immate_id, :aws_link, :original_link, :data_source_url]),
          :charges_and_bonds => MD5Hash.new(columns: [:charge_id, :bonds_id]),
        }
        
        inmates = @parser.give_current_page(current_page_html)
        inmate_files = @peon.give_list()
        inmates.each do |booking_id, inmate_values|
          booking_id = booking_id.gsub("/","_")
          next if !"#{booking_id}.gz".in?(inmate_files)
          logger.debug booking_id
          inmate_html = @peon.give(file: booking_id)
          inmate_id = put_inmate(booking_id, inmate_html)
          put_booking_details(inmate_id, booking_id, inmate_html)
          put_inmate_ids(inmate_id, booking_id, inmate_html)
          @peon.move(file: booking_id, to:today_string)
        end
      end		
    end
  end

  private

  def put_inmate( booking_id, html)
    inmates = @parser.inmates(booking_id, html)
    inmates[:run_id] = @run_id
    inmates[:touched_run_id] = @run_id
    inmates_md5_hash = @md5_hash_maker[:inmates].generate(inmates)
    inmates[:md5_hash] = inmates_md5_hash
    
    existed_row = @keeper.get_inmate_by_md5_hash(inmates_md5_hash)
    inmate_id = 
    if existed_row.nil?
      @keeper.save_inmates(inmates)
      @keeper.get_inmate_by_md5_hash(inmates_md5_hash).id
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
      existed_row.id
    end
  end 
  
  def put_booking_details(inmate_id, booking_id, html)
    details_arr = @parser.fetch_booking_details(booking_id, html)
    
    details_arr.each do |details|
      arrests = details[0]
      arrest_id = put_arrests(arrests, inmate_id)
      
      bonds = details[3]
      bonds_arr = put_bonds(bonds, arrest_id)
      
      charges = details[1]
      charges.each do |charged|
        charge = charged[0]
        charge_id = put_charge(charge, arrest_id)

        bonds_arr.each do |bonds_id|
          put_county_charges_and_bonds(bonds_id, charge_id,booking_id)
        end
        
        county_court_hearings = charged[1]
        put_county_court_hearings(county_court_hearings, charge_id)
      end
      
      facility = details[2]
      put_facility(facility, arrest_id, inmate_id)
    end
  end

  def put_arrests(arrests, inmate_id)
    arrests[:inmate_id] = inmate_id
    arrests[:run_id] = @run_id
    arrests[:touched_run_id] = @run_id
    arrests_md5_hash = @md5_hash_maker[:arrests].generate(arrests)
    arrests[:md5_hash] =  arrests_md5_hash

    existed_row = @keeper.get_arrests(arrests_md5_hash)
    arrest_id = 
    if existed_row.nil?
      @keeper.save_arrests(arrests)
      @keeper.get_arrests(arrests_md5_hash).id
    else
      existed_row.update(touched_run_id: @run_id, deleted:0)
      existed_row.id
    end
    arrest_id
  end

  def put_charge(charge, arrest_id)
    charge[:arrest_id] = arrest_id
    charge[:run_id] = @run_id
    charge[:touched_run_id] = @run_id
    charge_md5_hash = @md5_hash_maker[:charge].generate(charge)
    charge[:md5_hash] = charge_md5_hash

    existed_row = @keeper.get_charge(charge_md5_hash)
    charge_id =
      if existed_row.nil?
        @keeper.save_charge(charge)
        @keeper.get_charge(charge_md5_hash).id
      else
        existed_row.update(touched_run_id: @run_id, deleted: 0)
        existed_row.id
      end
    charge_id
  end

  def put_inmate_ids(inmate_id ,booking_id , html)
    inmate_ids = @parser.inmate_ids(booking_id ,html)
    inmate_ids[:inmate_id] = inmate_id
    inmate_ids[:run_id] = @run_id
    inmate_ids[:touched_run_id] = @run_id
    inmate_ids_md5_hash = @md5_hash_maker[:inmate_ids].generate(inmate_ids)
    inmate_ids[:md5_hash] = inmate_ids_md5_hash

    existed_row = @keeper.get_inmate_ids(inmate_ids_md5_hash)
      if existed_row.nil?
        @keeper.save_inmate_ids(inmate_ids)
      else
        existed_row.update(touched_run_id: @run_id, deleted: 0)
      end
  end

  def put_facility(facility, arrest_id, inmate_id)
    facility[:arrest_id] = arrest_id
    facility[:run_id] = @run_id
    facility[:touched_run_id] = @run_id
    facility_md5_hash = @md5_hash_maker[:county_holding_facilities].generate(facility)
    facility[:md5_hash] = facility_md5_hash

    existed_row = @keeper.get_holding_facility(facility_md5_hash)

    if existed_row.nil?
      @keeper.save_holding_facility(facility)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_county_court_hearings(county_court_hearings, charges_id)
    county_court_hearings[:charge_id] = charges_id
    county_court_hearings[:run_id] = @run_id
    county_court_hearings[:touched_run_id] = @run_id
    county_court_hearings_md5_hash = @md5_hash_maker[:county_holding_facilities].generate(county_court_hearings)
    county_court_hearings[:md5_hash] = county_court_hearings_md5_hash
    
    existed_row = @keeper.get_holding_county_court_hearings(county_court_hearings_md5_hash)

    if existed_row.nil?
      @keeper.save_holding_county_court_hearings(county_court_hearings)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_bonds(bonds_arr, arrest_id)
    bonds_ids = []
  
    bonds_arr.each do |bonds|
      bonds[:arrest_id] = arrest_id
      bonds[:run_id] = @run_id
      bonds[:touched_run_id] = @run_id
      bonds_md5_hash = @md5_hash_maker[:bonds].generate(bonds)
      bonds[:md5_hash] = bonds_md5_hash
  
      existed_row = @keeper.get_bonds(bonds_md5_hash)
  
      bonds_id =
        if existed_row.nil?
          @keeper.save_bonds(bonds)
          @keeper.get_bonds(bonds_md5_hash).id
        else
          existed_row.update(touched_run_id: @run_id, deleted: 0)
          existed_row.id
        end
      
      bonds_ids << bonds_id
    end
  
    bonds_ids
  end

  def put_county_charges_and_bonds(bonds_id, charge_id,booking_id)
    booking_id = booking_id.gsub("_", "/")
    charges_and_bonds = {}
    
    charges_and_bonds[:charge_id] = charge_id
    charges_and_bonds[:bond_id] = bonds_id
    charges_and_bonds[:run_id] = @run_id
    charges_and_bonds[:touched_run_id] = @run_id
    charges_and_bonds[:data_source_url] = @parser.fetch_data_url(booking_id)
    charges_and_bonds_md5_hash = @md5_hash_maker[:county_holding_facilities].generate(charges_and_bonds)
    charges_and_bonds[:md5_hash] = charges_and_bonds_md5_hash
    existed_row = @keeper.get_holding_charges_and_bonds(charges_and_bonds_md5_hash)

    if existed_row.nil?
      @keeper.save_holding_charges_and_bonds(charges_and_bonds)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

end