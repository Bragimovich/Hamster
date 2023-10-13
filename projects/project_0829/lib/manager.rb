require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'
require_relative '../models/wi_kenosha_runs'
require 'open-uri'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @peon = Peon.new(storehouse)
    @run_object = RunId.new(WiKenoshaRuns)
    @run_id = @run_object.last_id
  end

  FILENAME = 'full_list'

  def download
    response = @scraper.fetch_main_page
    doc = Nokogiri::HTML(response.body)
    pages = doc.css("select[name='Page']").text.squish.split("of")[-1].strip.split
    pages.each do |page|
      url = "http://inmate.kenoshajs.org/NewWorld.InmateInquiry/kenosha?Page=#{page}"
      current_page_html = @scraper.current_page_html(url)
      today_string = Date.today.to_s.gsub('-','_')
      current_page_file_name = "#{FILENAME}_page_#{page}_date_#{today_string}"
      sub_folder = "sub_folder_for_page_#{page}"
      @peon.put(content: current_page_html.body, file: current_page_file_name, sub_folder: sub_folder)
      inmates = @parser.current_page(current_page_html)
      existed_inmate_files = @peon.give_list()
      inmates.each do |booking_id, inmate|
        booking_id = booking_id.gsub("/","_")
        next if existed_inmate_files.include?("#{booking_id}.gz")
        inmate_page_html = @scraper.inmate_page(inmate[:link])
        @peon.put(content: inmate_page_html.body, file: booking_id)
        logger.debug "#{inmate} file added".green
      end
    end
  end

  def store
    response = @scraper.fetch_main_page
    doc = Nokogiri::HTML(response.body)
    pages = doc.css("select[name='Page']").text.squish.split("of")[-1].strip.split
    pages.each do |page|
      today_string = Date.today.to_s.gsub('-','_')
      current_page_file_name = "#{FILENAME}_page_#{page}_date_#{today_string}"
      current_page_html = @peon.give(file: current_page_file_name)
      return "FILE for #{today_string} is not exist" if current_page_html.nil?

      @md5_hash_maker = {
        :inmate_statuses => MD5Hash.new(columns:[:inmate_id, :status, :date_of_status_change, :data_source_url]),
        :inmates => MD5Hash.new(columns:[:full_name, :sex, :data_source_url]),
        :inmate_additional_info => MD5Hash.new(columns:[:inmate_id, :height, :weight, :data_source_url]),
        :inmate_ids => MD5Hash.new(columns:[:inmate_id, :number, :type, :data_source_url ]),
        :inmate_addresses => MD5Hash.new(columns:[:inmate_id, :full_address, :zip, :state, :city, :data_source_url]),
        :mugshots => MD5Hash.new(columns:[:inmate_id, :aws_link, :original_link, :data_source_url]),
        :arrests => MD5Hash.new(columns:[:inmate_id, :booking_number, :booking_date, :booking_agency, :data_source_url]),
        :arrests_additional => MD5Hash.new(columns:[:arrest_id, :key, :value, :data_source_url]),
        :bonds => MD5Hash.new(columns:[:arrest_id, :bond_amount, :data_source_url]),
        :bonds_additoinal => MD5Hash.new(columns:[:bond_id, :key, :value, :data_source_url]),
        :charges => MD5Hash.new(columns:[:arrest_id, :docket_number, :disposition, :disposition_date, :description, :crime_class, :attempt_or_commit, :data_source_url]),
        :charges_additional => MD5Hash.new(columns:[:charge_id, :key, :value, :data_source_url]),
        :holding_facilities => MD5Hash.new(columns:[:arrest_id, :actual_release_date, :facility, :data_source_url]),
      }
      inmates = @parser.give_current_page(current_page_html)
      inmate_files = @peon.give_list()
      inmates.each do |booking_id, inmate_values|
        booking_id = booking_id.gsub("/","_")
        next if !"#{booking_id}.gz".in?(inmate_files)
        
        logger.debug booking_id
        inmate_html = @peon.give(file: booking_id)
        next if inmate_html.include?("An error occurred while processing your request.")
        inmate_id = put_inmate(booking_id, inmate_html)
        put_inmate_additional_info(booking_id, inmate_html, inmate_id)
        put_inmates_id(booking_id, inmate_html, inmate_id)
        put_inmate_addresses(booking_id, inmate_html, inmate_id)
        put_mugshots(booking_id, inmate_html, inmate_id)
        put_booking_details(booking_id, inmate_html, inmate_id)
        @peon.move(file: booking_id, to: today_string)
      end
    end
    @keeper.finish_with_models(@run_id)
  end

  private

  def put_inmate(booking_id, html)
    inmates = @parser.inmates(booking_id, html)
    inmates[:run_id] = @run_id
    inmates[:touched_run_id]= @run_id
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
    inmate_id
  end

  def put_inmate_additional_info(booking_id, html, inmate_id)
    inmate_additional_info = @parser.inmate_additional_info(booking_id, html)
    inmate_additional_info[:inmate_id] = inmate_id
    inmate_additional_info[:run_id] = @run_id
    inmate_additional_info[:touched_run_id] = @run_id
    inmate_additional_info_md5_hash = @md5_hash_maker[:inmate_additional_info].generate(inmate_additional_info)
    inmate_additional_info[:md5_hash] = inmate_additional_info_md5_hash

    existed_row = @keeper.get_inmate_additional_info_hash(inmate_additional_info_md5_hash)

    if existed_row.nil?
      @keeper.save_inmate_additional_info(inmate_additional_info)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_inmates_id(booking_id, html, inmate_id)
    inmate_ids = @parser.inmate_ids(booking_id, html)
    inmate_ids[:inmate_id] = inmate_id
    inmate_ids[:run_id] = @run_id
    inmate_ids[:touched_run_id] = @run_id
    inmate_id_md5_hash = @md5_hash_maker[:inmate_ids].generate(inmate_ids)
    inmate_ids[:md5_hash] = inmate_id_md5_hash

    existed_row = @keeper.get_inmate_id(inmate_id_md5_hash)

    if existed_row.nil?
      @keeper.save_inmate_id(inmate_ids)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_inmate_addresses(booking_id, html, inmate_id)
    inmate_addresses = @parser.inmate_addresses(booking_id, html)
    inmate_addresses[:inmate_id] = inmate_id
    inmate_addresses[:run_id] = @run_id
    inmate_addresses[:touched_run_id] = @run_id
    inamte_addresses_md5_hash = @md5_hash_maker[:inmate_addresses].generate(inmate_addresses)
    inmate_addresses[:md5_hash] = inamte_addresses_md5_hash

    existed_row = @keeper.get_inmate_addresses(inamte_addresses_md5_hash)

    if existed_row.nil?
      @keeper.save_inmate_addresses(inmate_addresses)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
   end

  def put_mugshots(booking_id, html, inmate_id)
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    base_url = "http://inmate.kenoshajs.org"
    pict_link , mugshots = @parser.mugshots(booking_id, html)
    inmate_detail_link = mugshots[:data_source_url]
    url = base_url + pict_link if pict_link.nil? == false
    begin
      image_data = open(url).read
    rescue
      logger.debug "image data not found"
    end
    
    aws_link = @aws_s3.put_file(image_data, "inmates/wi/kenosha/#{inmate_detail_link}.webp") if image_data.nil? == false
    mugshots[:run_id] = @run_id
    mugshots[:touched_run_id] = @run_id
    mugshots[:inmate_id] = inmate_id
    mugshots[:aws_link] = aws_link
    mugshots[:original_link] = url
    mugshot_md5_hash = @md5_hash_maker[:mugshots].generate(mugshots)
    mugshots[:md5_hash] = mugshot_md5_hash

    existed_row = @keeper.get_mugshot(mugshot_md5_hash)

    if existed_row.nil?
      @keeper.save_mugshots(mugshots)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end
  
  def put_booking_details(booking_id, html, inmate_id)
    details_arr = @parser.fetch_booking_details(booking_id, html)
    details_arr.each do |details|
      arrests = details[0]
      arrest_id = put_arrests(arrests, inmate_id)
      
      arrests_additional = details[4]
      put_arrest_additional(arrests_additional, arrest_id)
      
      bonds = details[1]
      bond_id = put_bonds(bonds, arrest_id)

      bonds_additoinal = details[5]
      put_bond_additional(bonds_additoinal, bond_id)
      
      charges = details[2]
      put_charges(charges, arrest_id)
      
      facility = details[3]
      put_facility(facility, arrest_id, inmate_id)
      
    end
  end

  def put_arrests(arrests, inmate_id)
    arrests[:inmate_id] = inmate_id
    arrests[:run_id] = @run_id
    arrests[:touched_run_id] = @run_id
    arrests_md5_hash = @md5_hash_maker[:arrests].generate(arrests)
    arrests[:md5_hash] = arrests_md5_hash

    existed_row = @keeper.get_arrest(arrests_md5_hash)
    arrest_id =
      if existed_row.nil?
        @keeper.save_arrest(arrests)
        @keeper.get_arrest(arrests_md5_hash).id
      else
        existed_row.update(touched_run_id: @run_id, deleted: 0)
        existed_row.id
      end
    arrest_id
  end

  def put_arrest_additional(arrests_additional, arrest_id)
    arrests_additional[:arrest_id] = arrest_id
    arrests_additional[:run_id] = @run_id
    arrests_additional[:touched_run_id] = @run_id
    arrests_additional_md5_hash = @md5_hash_maker[:arrests_additional].generate(arrests_additional)
    arrests_additional[:md5_hash] = arrests_additional_md5_hash

    existed_row = @keeper.get_arrest_additional(arrests_additional_md5_hash)

    if existed_row.nil?
      @keeper.save_arrest_additional(arrests_additional)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_bonds(bonds, arrest_id)
    bonds[:arrest_id] = arrest_id
    bonds[:run_id] = @run_id
    bonds[:touched_run_id] = @run_id
    bonds_md5_hash = @md5_hash_maker[:bonds].generate(bonds)
    bonds[:md5_hash] = bonds_md5_hash

    existed_row = @keeper.get_bond(bonds_md5_hash)

    bond_id =
      if existed_row.nil?
        @keeper.save_bond(bonds)
        @keeper.get_bond(bonds_md5_hash).id
      else
        existed_row.update(touched_run_id: @run_id, deleted: 0)
        existed_row.id
      end
    bond_id
  end

  def put_bond_additional(bonds_additoinal, bond_id)
    bonds_additoinal[:bond_id] = bond_id
    bonds_additoinal[:run_id] = @run_id
    bonds_additoinal[:touched_run_id] = @run_id
    bonds_additoinal_md5_hash = @md5_hash_maker[:bonds_additoinal].generate(bonds_additoinal)
    bonds_additoinal[:md5_hash] = bonds_additoinal_md5_hash

    existed_row = @keeper.get_bond_additional(bonds_additoinal_md5_hash)

    if existed_row.nil?
      @keeper.save_bond_additional(bonds_additoinal)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_charges(charges, arrest_id)
    charges.each do |charge|
      charges = charge[0]
      charge_id = put_charge(charges, arrest_id)

      charges_additional = charge[1]
      put_charge_additional(charges_additional, charge_id)
      
    end
  end

  def put_charge(charges, arrest_id)
    charges[:arrest_id] = arrest_id
    charges[:run_id] = @run_id
    charges[:touched_run_id] = @run_id
    charges_md5_hash = @md5_hash_maker[:charges].generate(charges)
    charges[:md5_hash] = charges_md5_hash

    existed_row = @keeper.get_charge(charges_md5_hash)

    charge_id =
      if existed_row.nil?
        @keeper.save_charge(charges)
        @keeper.get_charge(charges_md5_hash).id
      else
        existed_row.update(touched_run_id: @run_id, deleted: 0)
        existed_row.id
      end
    charge_id
  end

  def put_charge_additional(charges_additional, charge_id)
    charges_additional[:charge_id] = charge_id
    charges_additional[:run_id] = @run_id
    charges_additional[:touched_run_id] = @run_id
    charges_additional_md5_hash = @md5_hash_maker[:charges_additional].generate(charges_additional)
    charges_additional[:md5_hash] = charges_additional_md5_hash
    
    existed_row = @keeper.get_charge_additional(charges_additional_md5_hash)

    if existed_row.nil?
      @keeper.save_charge_additional(charges_additional)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_facility(facility, arrest_id, inmate_id)
    facility[:arrest_id] = arrest_id
    facility[:run_id] = @run_id
    facility[:touched_run_id] = @run_id
    facility_md5_hash = @md5_hash_maker[:holding_facilities].generate(facility)
    facility[:md5_hash] = facility_md5_hash

    existed_row = @keeper.get_holding_facility(facility_md5_hash)

    if existed_row.nil?
      @keeper.save_holding_facility(facility)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
    if facility[:actual_release_date].nil? == true || facility[:actual_release_date].empty? == true
      put_inmate_status(inmate_id)
    end
  end

  def put_inmate_status(inmate_id)
    inmate_status = {}
    inmate_status[:inmate_id] = inmate_id
    inmate_status[:status] = "In Custody"
    inmate_status[:date_of_status_change] = Time.current
    inmate_status[:run_id] = @run_id
    inmate_status[:touched_run_id] = @run_id
    inmate_status_md5_hash = @md5_hash_maker[:inmate_statuses].generate(inmate_status)
    inmate_status[:md5_hash] = inmate_status_md5_hash

    existed_row = @keeper.get_inmate_status(inmate_status_md5_hash)

    if existed_row.nil?
      @keeper.save_inmate_status(inmate_status)
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
    end
  end
end
