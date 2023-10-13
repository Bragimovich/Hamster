# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @sub_folder = "RunID_#{keeper.run_id}"
    @already_fetched_offenders =  @keeper.get_offenders().map{|e| e.split("/").last}
    @run_id = keeper.run_id
    @sub_folder = "RunID_#{@run_id}"
  end

  def download
    scraper = Scraper.new
    parser = Parser.new

    @first_name = ('a'..'z').map(&:to_s)
    @last_name = ('a'..'z').map(&:to_s)

    @first_name.each do |first_letter|

      puts "Currently First Name on -> #{first_letter}"
      @last_name.each do |last_letter|

        puts "Currently Last Name on -> #{last_letter}"
        response = scraper.fetch_main_page
        cookie = response.headers["set-cookie"]
        token = parser.get_access_token(response)

        solved_captcha = captcha_solver(token)
        response = scraper.captcha_verify(solved_captcha, token, cookie)
        old_cookie = cookie
        cookie = response.headers["set-cookie"]
        new_cookie = old_cookie + ";#{cookie.split(";").first};"

        processor(scraper, parser, first_letter, last_letter, token, new_cookie, old_cookie)
      end
    end

  end

  def store
    parser = Parser.new

    offenders_files = peon.list(subfolder: sub_folder).delete_if { |x| x == ".DS_Store" }
    offenders_files.each do |file|
      data_hash = {}
      next if  @already_fetched_offenders.include? file.gsub(".gz", "")

      file = peon.give(file: file, subfolder: sub_folder)
      data_hash = parser.parse_offender(file, @run_id)
      arrestee_id = keeper.insert_arrestees(data_hash) unless data_hash.empty?

      hash_array = parser.parse_marks(file, @run_id, arrestee_id)
      keeper.insert_marks(hash_array) unless hash_array.empty?

      hash_array = parser.parse_arrestee_aliases(file, @run_id, arrestee_id)
      keeper.insert_arrestee_aliases(hash_array) unless hash_array.empty?

      data_hash = parser.parse_reg_information(file, @run_id, arrestee_id)
      keeper.insert_reg_information(data_hash) unless data_hash.empty?

      data_hash = parser.parse_mugshots(file, @run_id, arrestee_id)
      keeper.insert_mugshots(data_hash) unless data_hash.empty?

      manage_address(parser, file, arrestee_id, @run_id)

      manage_vehicales(parser, file, arrestee_id, @run_id)
      manage_convictions(parser, file, arrestee_id, @run_id)
      manage_agency_address(parser, file, arrestee_id, @run_id)

    end
    keeper.finish
  end

  def processor(scraper, parser, first_letter, last_letter, token, cookie, old_cookie)
    response = scraper.search_request(first_letter,last_letter,token,cookie)

    return if parser.fetch_json(response.body)["ids"].nil?

    offenders_id = parser.get_offenders(response)
    offenders_id.each do |id|

      next if  @already_fetched_offenders.include? id.to_s

      puts "Currently Offender ID --> #{id}"
      response = scraper.search_offender(id,token,cookie)
      data =  parser.fetch_json(response.body)
      if parser.fetch_json(response.body)["needsCaptcha"] == true
        p "Captcha Needed"
        solved_captcha = captcha_solver(token)
        response = scraper.captcha_verify(solved_captcha, token, old_cookie)
        cookie = response.headers["set-cookie"]
        response = scraper.search_offender(id,token,cookie)
        data =  parser.fetch_json(response.body)
      end
      save_file(response, id , "#{sub_folder}")
    end

  end

  def manage_address(parser, file, arrestee_id, run_id)
    address_list  = parser.get_address_list(file)
    return if address_list.empty?
    address_list.each do |address|

      state_hash = parser.parse_state(address)
      if !state_hash.nil?
        state_id = keeper.insert_state(state_hash)
      else
        state_id = nil
      end

      city_hash = parser.parse_city(address, state_id)
      if !city_hash.nil?
        city_id = keeper.insert_city(city_hash)
      else
        city_id = nil
      end

      zip_hash = parser.parse_zip(address)
      if !zip_hash.nil?
        zip_id = keeper.insert_zip(zip_hash)
      else
        zip_id = nil
      end

      add_hash = parser.parse_address(address, @run_id, arrestee_id, state_id, city_id, zip_id, file)
      if add_hash[:full_address] != ","
        add_id = keeper.insert_add(add_hash) unless add_hash.empty?
        arrestee_add = parser.arrestee_address(@run_id, add_id, address, file, arrestee_id)
        keeper.insert_arrestee_address(arrestee_add) unless add_hash.empty?
      end
    end
  end

  def manage_vehicales(parser, file, arrestee_id, run_id)
    vehical_list = parser.get_vehical_list(file)
    return if vehical_list.empty?
    vehical_list.each do |vehical|

      state_hash = parser.parse_state(vehical)
      state_id = keeper.insert_state(state_hash)
      data_hash = parser.parse_vehicles(vehical, state_id, arrestee_id, run_id, file)
      keeper.insert_vehicles(data_hash) unless data_hash.empty?
    end
  end

  def manage_convictions(parser, file, arrestee_id, run_id)
    convictions_list = parser.get_convictions(file)
    return if convictions_list.empty?
    convictions_list.each do |convictions|

      state_hash = parser.parse_state(convictions)
      if !state_hash.nil?
      	state_id = keeper.insert_state(state_hash)
      else
      	state_id = nil
      end
      data_hash = parser.parse_convictions(convictions, state_id, arrestee_id, file)
      keeper.insert_convictions(data_hash)
    end
  end

  def manage_agency_address(parser, file, arrestee_id, run_id)
    address = parser.get_agency_address(file)

    if !address.empty?
      state_hash = parser.parse_state(address)
      if !state_hash.nil?
        state_id = keeper.insert_state(state_hash)
      else
        state_id = nil
      end

      city_hash = parser.parse_city(address, state_id)
      if !city_hash.nil?
        city_id = keeper.insert_city(city_hash)
      else
        city_id = nil
      end

      zip_hash = parser.parse_zip(address)
      if !zip_hash.nil?
        zip_id = keeper.insert_zip(zip_hash)
      else
        zip_id = nil
      end

      add_hash = parser.parse_address(address, run_id, arrestee_id, state_id, city_id, zip_id, file)
      if add_hash[:full_address] != ","
        add_id = keeper.insert_add(add_hash)
        agency_hash = parser.parse_agency(run_id, add_id, file, arrestee_id)
        agency_id = keeper.insert_agency(agency_hash)
        ar_agency_hash = parser.parse_arrestee_agency(run_id, agency_id, arrestee_id)
        keeper.insert_arrestee_agency(ar_agency_hash)
      else
        agency_hash = parser.parse_agency(run_id, nil, file, arrestee_id)
        agency_id = keeper.insert_agency(agency_hash)
        ar_agency_hash = parser.parse_arrestee_agency(run_id, agency_id, arrestee_id)
        keeper.insert_arrestee_agency(ar_agency_hash)
      end
    else
      agency_hash = parser.parse_agency(run_id, nil, file, arrestee_id)
      agency_id = keeper.insert_agency(agency_hash)
      ar_agency_hash = parser.parse_arrestee_agency(run_id, agency_id, arrestee_id)
      keeper.insert_arrestee_agency(ar_agency_hash)
    end
  end

  private

  attr_accessor :keeper, :sub_folder

  def captcha_solver(token, retries = 3)
    two_captcha = TwoCaptcha.new(Storage.new.two_captcha['general'], timeout:200, polling:5)
    p "Balance is -> #{two_captcha.balance}"
    options = {
      pageurl: "https://sexoffender.dsp.delaware.gov",
      googlekey: token[:data_sitekey]
    }
    begin
      decoded_captcha = two_captcha.decode_recaptcha_v2!(options)
      decoded_captcha.text
    rescue StandardError => e
      p e.full_message
      raise if retries <= 1
      captcha_solver(token, retries - 1)
    end
  end

  def save_file(response, file_name , sub_folder)
    peon.put content: response.body, file: file_name, subfolder: sub_folder
  end

end
