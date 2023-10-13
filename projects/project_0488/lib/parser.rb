# frozen_string_literal: true
require_relative 'keeper'

class ILWillParser < Hamster::Parser
  def initialize(run = 1)
    super
    @keeper = ILWillKeeper.new(run)
    @run = run
  end

  def get_bookers_links(pg, type)
    links_data = []
    html = Nokogiri::HTML(pg)
    html.at('.Grid td')&.content
    return 'all pages proceed' if html.at('.Grid td')&.content == 'No data'
    links = html.css('.Grid td a').map{|i| "http://66.158.36.230" + i['href']}
    arrestees_names = html.css('.Grid td a').map{|i| i&.content}
    statuses =  html.css('.Grid td.InCustody').map{|i| i&.content}
    links.each_with_index do |link, i|
      links_data << [link, arrestees_names[i], statuses[i].to_s]
      save_public_arrestees_list(link, arrestees_names[i], statuses[i]) if type == 'Public'
    end
    links_data
  end
  def store
    files = peon.give_list(subfolder: "run_#{@run}_bookers_press")
    files.each do |file|
      data_page = peon.give(subfolder: "run_#{@run}_bookers_press", file: file).encode("UTF-8", invalid: :replace, replace: "")
      link = split_link(data_page)
      booker_page = split_html(data_page)
      @status = split_status(data_page)
      p file, link
      @booker = {}
      @booker[:data_source_url] = link
      @booker[:arrestee_id] = get_arrestee_id
      booker_data = parse_booker_page(booker_page)
      next if booker_data == 'Error'
      @keeper.store_data(@booker)
      peon.move(file: file, from: "run_#{@run}_bookers_press", to: "run_#{@run}_bookers_press")
    end
    move_index_pages
    @keeper.check_deleted
    Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #488 Crime Data for Perps held on Bail - Will, IL parsing data completed successfully."
  end

  private
  def get_arrestee_id
    arrestee_id = (/[0-9]{1,}$/.match(@booker[:data_source_url]).to_s)
    arrestee_id
  end
  def move_index_pages
    types = ['public', 'press']
    types.each do |type|
      files = peon.give_list(subfolder: "run_#{@run}_index_#{type}")
      files.each do |file|
        peon.move(file: file, from: "run_#{@run}_index_#{type}", to: "run_#{@run}_index_#{type}")
      end
    end
  end
  def save_public_arrestees_list(link, name, status)
    arrestee_number = (/[0-9]{1,}$/.match(link).to_s)
    status = 0 if status.to_s == ''
    record = "#{arrestee_number}|||#{name}|||#{status}"
    public_info_list_path = "#{ENV['HOME']}/HarvestStorehouse/project_0488/store/public_records_list/public_records_run_#{@run}"
    File.open(public_info_list_path,"a") do |f|
      f.puts record
    end
  end
  def parse_booker_page(page)
    @html = Nokogiri::HTML(page)
    warn = check_brocken_page
    unless warn
    get_demographic_data
    get_booker_arests
    else
      return warn
    end
  end
  def check_brocken_page
    header = @html.at('.Header h1')&.content.to_s.strip
    warn = (header == 'Error' ? 'Error' : nil)
    warn
  end
  def get_demographic_data
    @booker_demographic_info = @html.at('#DemographicInformation')&.content.gsub(/\r|\t/,'').squeeze("\n").strip.gsub("\n", ': ')
    @booker[:full_name] = get_booker_full_name
    first_name, middle_name, last_name, suffix = parse_full_name(@booker[:full_name])
    @booker[:first_name] = first_name
    @booker[:middle_name] = middle_name
    @booker[:last_name] = last_name
    @booker[:suffix] = suffix
    @booker[:age] = get_booker_age
    @booker[:gender] = get_booker_gender
    @booker[:race] = get_booker_race
    @booker[:height] = get_booker_height
    @booker[:weight] = get_booker_weight
    @booker[:aliases] = get_booker_aliases
    @booker[:street_address] = get_booker_street_address
    city_state_zip, city, state, zip = get_booker_city_state_zip
    @booker[:city_state_zip] = city_state_zip
    @booker[:city] = city
    @booker[:state] = state
    @booker[:zip] = zip
    @booker[:mugshots] = get_booker_mugshots
  end
  def get_booker_full_name
    begin
      full_name = /Name: [A-Za-z0-9.,\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Name: ', '')
      (full_name == 'Age') ? nil : full_name
  rescue => e
    end
  end
  def get_booker_age
    begin
      age = /Age: [A-Za-z0-9.,\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Age: ', '')
      (age == 'Gender') ? nil : age
    rescue => e
    end
  end
  def get_booker_gender
    begin
      gender = /Gender: [A-Za-z0-9.,\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Gender: ', '')
      (gender == 'Race') ? nil : gender
  rescue => e
    end
  end
  def get_booker_race
    begin
      race = /Race: [A-Za-z0-9.,\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Race: ', '')
      (race == 'Height') ? nil : race
  rescue => e
    end
  end
  def get_booker_height
    begin
      height = /Height: [A-Za-z0-9.,'"\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Height: ', '')
      (height == 'Weight') ? nil : height
    rescue => e
    end
  end
  def get_booker_weight
    begin
      weight = /Weight: [A-Za-z0-9.,\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Weight: ', '')
      (weight == 'Address') ? nil : weight
    rescue => e
    end
  end
  def get_booker_aliases
    begin
      /Aliases: [A-Za-z0-9.,'"&#!\s-]{1,}/.match(@booker_demographic_info)[0].gsub('Aliases: ', '')
    rescue => e
    end
  end
  def get_booker_street_address
    begin
      @html.at('.Street')&.content
    rescue => e
    end
  end
  def get_booker_city_state_zip
    begin
      city_state_zip = @html.at('.CityState')&.content
      city = city_state_zip&.split(', ')&.first
      city = ((city.downcase == 'illinois' || !city.scan(/\d{1,}/).empty?) ? nil : city)
      state = city_state_zip&.split(', ')&.last&.scan(/[A-Za-z ]{1,}/)&.first&.strip
      state = nil if city && city.include?(',')
      city = city.gsub(',', '')
      city = nil if city == ''
      state = nil if state == ''
      zip = city_state_zip&.scan(/\d{1,}-?\d{0,}$/)&.first
      [city_state_zip, city, state, zip]
    rescue => e
    end
  end
  def get_booker_mugshots
    info = []
    mugshots_info = @html.css('.BookingPhotos a')
    mugshots_links = mugshots_info.map{|i| "http://66.158.36.230" + i['href']}
    mugshots_dates = mugshots_info.map{|i| i&.content}

    mugshots_links.each_with_index do |link, i|
      h = {}
      h[:original_link] = link
      mugshots_dates[i].strip
      h[:notes] = mugshots_dates[i]&.strip
      info << h
    end
    @booker[:mugshots] = info
end
  def get_booker_arests
    booker_history = @html.css('.Booking')
    h = []
    booker_history.each_with_index do |history, i|
      @arest = history
      status = @status if i == 0
      h << proceed_arest(status)
    end
    h
  end
  def proceed_arest(status = nil)
    booking_number = get_booking_number
    booking_date, actual_release_date, booking_agency, facility, booking_agency_subtype  = get_arest_total_info
    charges = get_charges
    bonds = get_bonds
    hearings = get_hearings
    @booker[:booking_numbers] ||= []
    @booker[:booking_numbers] << {booking_number: booking_number,
                                  booking_date: booking_date,
                                  actual_release_date: actual_release_date,
                                  booking_agency: booking_agency,
                                  booking_agency_subtype: booking_agency_subtype,
                                  status: status,
                                  facility: facility,
                                  charges: charges,
                                  bonds: bonds,
                                  hearings: hearings}

    [booking_number, booking_date, actual_release_date, booking_agency, facility, charges, bonds, hearings]
  end
  def get_booking_number
    @arest.at('h3')&.content.to_s.sub('Booking', '').strip
  end
  def get_arest_total_info
    @arest_total_info = @arest.at('.BookingData .FieldList')&.content.gsub(/\r|\t/,'').squeeze("\n").strip.gsub("\n", ': ')
    [get_booking_date, get_release_date, get_booking_agency, get_facility, get_booking_agency_subtype]
  end
  def get_booking_date
    begin
    booking_date = /Booking Date: [0-9\/]{1,}/.match(@arest_total_info)[0].gsub('Booking Date: ', '')
    Date.strptime( booking_date, '%m/%d/%Y').to_s
    rescue => e
    end
  end
  def get_release_date
    release_date = /Release Date: [0-9\/]{1,}/.match(@arest_total_info)
    Date.strptime(release_date[0].gsub('Release Date: ', ''), '%m/%d/%Y').to_s if release_date
  end
  def get_booking_agency
    booking_agency = /Booking Origin: [A-Za-z0-9.,'"\s-]{1,}/.match(@arest_total_info)
    booking_agency = booking_agency[0].gsub('Booking Origin: ', '') if booking_agency
    booking_agency
  end
  def get_facility
    housing_fasility = /Housing Facility: [A-Za-z0-9.,'"\s-]{1,}/.match(@arest_total_info)[0].gsub('Housing Facility: ', '')
    nil if housing_fasility == "Total Bond Amount"
  end
  def get_booking_agency_subtype
    booking_agency = get_booking_agency
    booking_agency_subtype = if booking_agency && booking_agency.include?("POLICE DEPARTMENT")
                              'POLICE DEPARTMENT'
                            elsif booking_agency && booking_agency.include?("SHERIFF'S OFFICE")
                             "SHERIFF'S OFFICE"
                            elsif booking_agency && booking_agency.include?("ISP")
                             "STATE POLICE"
                            end
    booking_agency_subtype
  end
  def get_charges
    charge_arr = []
    charges_total_info = @arest.css('.BookingCharges tr').to_a
    charges_total_info.slice!(0)
    charges_total_info.each do |charge|
    @charge_info = charge&.content.gsub(/\r|\t/,'').squeeze("\n").strip.gsub("\n", '|||')

    charge_number = charge.at('.SeqNumber')&.content
    charge_description = charge.at('.ChargeDescription')&.content
    offense_date_time = charge.at('.OffenseDate')&.content
    docket_number = charge.at('.DocketNumber')&.content
    sentence_date = charge.at('.SentenceDate')&.content
    sentence_date = Date.strptime(sentence_date, '%m/%d/%Y').to_s if sentence_date && sentence_date != ''
    sentence_length = charge.at('.SentenceLength')&.content
    crime_class = charge.at('.CrimeClass')&.content
    arresting_agency = charge.at('.ArrestingAgencies')&.content
    attempt_or_commit = charge.at('.AttemptCommit')&.content
    charge_number = nil if charge_number == 'No data'
    charge_description = nil if charge_description == ''
    offense_date_time = nil if offense_date_time == ''
    docket_number = nil if docket_number == ''
    sentence_date = nil if sentence_date == ''
    sentence_length = nil if sentence_length == ''
    crime_class = nil if crime_class == ''
    arresting_agency = nil if arresting_agency == ''
    attempt_or_commit = nil if attempt_or_commit == ''
    charge_arr << {charge_number: charge_number.to_i,
                   charge_description: charge_description,
                   offense_date_time: offense_date_time,
                   docket_number: docket_number,
                   sentence_date: sentence_date,
                   sentence_length: sentence_length,
                   crime_class: crime_class,
                   arresting_agency: arresting_agency,
                   attempt_or_commit: attempt_or_commit}
    end
    charge_arr
  end
  def get_bonds
    bonds_arr = []
    bonds_total_info = @arest.css('.BookingBonds tr').to_a
    bonds_total_info.slice!(0)
    bonds_total_info.each do |bond|
      @bond_info = bond&.content.gsub(/\r|\t/,'').squeeze("\n").strip.gsub("\n", '|||')
      bond_number, bond_type, bond_amount = @bond_info.split('|||')
      bond_number = nil if bond_number == 'No data'
      bonds_arr << {bond_number: bond_number, bond_type: bond_type, bond_amount: bond_amount}
    end
    bonds_arr
  end
  def get_hearings
    hearings_arr = []
    hearings_total_info = @arest.css('.BookingCourtInfo tr').to_a
    hearings_total_info.slice!(0)
    hearings_total_info.each do |hearing|
      @hearings_info = hearing&.content.gsub(/\r|\t/,'').squeeze("\n").strip.gsub("\n", '|||')
      charge_numbers, court_date_time, court_room = @hearings_info.split('|||')
      if charge_numbers == 'No data'
      charge_numbers = nil
      hearings_arr << {charge_number: charge_numbers, court_date_time: court_date_time, court_room: court_room}
      else
        charge_numbers.split(', ').each do |charge_number|
          hearings_arr << {charge_number: charge_number.to_i, court_date_time: court_date_time, court_room: court_room}
        end
      end
    end
    hearings_arr
  end
  def parse_full_name(name)
    if name
      last_name = name.split(', ').first
      first_name, middle_name, suffix =  name.split(', ').last.split(' ')
      [first_name, middle_name, last_name, suffix]
    end
  end
  def move_to_trash(file)
    peon.move(file: file, from: 'releases', to: 'releases')
  end
  def split_link(file_content)
    file_content.split('|||').first
  end
  def split_html(file_content)
    file_content.split('|||')[1]
  end
  def split_status(file_content)
    (file_content.split('|||').last == 'Yes') ? 'In Custody' : nil
  end
end