require 'date'

class Parser < Hamster::Parser
  def current_page(source)
    page = Nokogiri::HTML(source.body)
    @persons_general = {}
    page.css('tr')[1..].each do |row|
      link = row.css('a')[0]
      booking_id = link['href']
      @persons_general[booking_id] =
      {
        name: link.content,
        link: 'http://50.239.65.109' + link['href'],
      }
    end
    @persons_general
  end
  
  def give_current_page(source)
    page = Nokogiri::HTML source

    @persons_general = {}

    page.css('tr')[1..].each do |row|
      link = row.css('a')[0]
      booking_id = link['href']
      @persons_general[booking_id] =
      {
        name: link.content,
        link: 'http://50.239.65.109' + link['href'],
      }
    end
    @persons_general
  end

  def inmates(booking_id, html)
    booking_id = booking_id.gsub("_", "/")
    page = Nokogiri::HTML html
    inmate = {}
    demographic_information = page.children[1].children[3].css('div#DemographicInformation').css('ul')
    date_of_birth_str = demographic_information.css('li span')[2].text
    if date_of_birth_str.nil? == false && !date_of_birth_str.empty?
      date_of_birth = DateTime.strptime(date_of_birth_str, "%m/%d/%Y")
      formated_date = date_of_birth.strftime("%Y-%m-%d")
    else
    end
    inmate[:full_name] = demographic_information.css('li span')[0].text
    name_parts = inmate[:full_name].split(",").map(&:strip)
    if name_parts.length > 2
      inmate[:first_name] = demographic_information.css('li span')[0].text.strip.split(",")[0].sub(" ", "")
      inmate[:middle_name] = demographic_information.css('li span')[0].text.strip.split(",")[1].sub(" ", "")
      inmate[:last_name] = demographic_information.css('li span')[0].text.strip.split(",")[2].sub(" ", "")
    else
      inmate[:first_name] = demographic_information.css('li span')[0].text.strip.split(",")[0].sub(" ", "")
      inmate[:last_name] = demographic_information.css('li span')[0].text.strip.split(",")[1].sub(" ", "")
    end
    inmate[:birthdate] = formated_date if formated_date.nil? == false
    inmate[:data_source_url] = fetch_data_url(booking_id)
  
    inmate
  end

  def fetch_booking_details(booking_id, html)
    page = Nokogiri::HTML(html)
    booking_id = booking_id.gsub("_","/")
    bookings = page.css('.Booking')
    details_arr = []
    detail_arr = []
  
    bookings.each do |booking|
      arrest_data = arrests(booking_id, booking)
      detail_arr << arrest_data
      charges_data = charges(booking_id , booking)
      detail_arr << charges_data
      facility_date = holding_facility(booking_id,booking)
      detail_arr << facility_date
      bonds_data = bonds(booking_id, booking)
      detail_arr << bonds_data
    end
    details_arr << detail_arr
    details_arr
  end

  def arrests(booking_id, booking)
    arrest_date_str = booking.at_css('.BookingDate span').text if booking.at_css('.BookingDate span').nil? == false 
    formatted_date = format_date(arrest_date_str)
    
    arrests = {}
    arrests[:booking_number] = booking.at_css('h3 span').text if booking.at_css('h3 span').nil? == false 
    arrests[:booking_date] = formatted_date if formatted_date.nil? == false
    arrests[:data_source_url] = fetch_data_url(booking_id)
    arrests
  end

  def charges(booking_id, booking)
    booking_id = booking_id.gsub("_","/")
    charges_detail = []
    charges_table = booking.at_css('.BookingCharges table')
    charges_rows = charges_table.css('tbody tr')
    
    charges_rows.each do |charge|
      offence_date_str = charge.at_css('.OffenseDate').text if charge.at_css('.OffenseDate').nil? == false
      if offence_date_str.nil? == false && !offence_date_str.empty?
        offence_date = DateTime.strptime(offence_date_str, "%m/%d/%Y")
        formated_date = offence_date.strftime("%Y-%m-%d")
      else
      end
      county_court_hearings = {}
      charge_data = {}
      charge_data[:docket_number] = charge.at_css('.DocketNumber').text if charge.at_css('.DocketNumber').nil? == false
      charge_data[:offense_date] = formated_date if formated_date.nil? == false
      charge_data[:disposition] = charge.at_css('.Disposition').text if charge.at_css('.Disposition').nil? == false
      charge_data[:charge_number] = charge.at_css('.ChargeDescription').text if charge.at_css('.ChargeDescription').nil? == false
      charge_data[:crime_class] = charge.at_css('.CrimeClass').text if charge.at_css('.CrimeClass').nil? == false
      charge_data[:data_source_url] = fetch_data_url(booking_id)
        
      hearing_table = booking.at_css('.BookingCharges table')
      hearing_rows = hearing_table.css('tbody tr')
      county_court_hearings[:court_date] = hearing_rows.at_css('.CourtDate').text if hearing_rows.at_css('.CourtDate').nil? == false
      county_court_hearings[:sentence_lenght] = hearing_rows.at_css('.SentenceLength').text if  hearing_rows.at_css('.SentenceLength').nil? == false
      county_court_hearings[:data_source_url] = fetch_data_url(booking_id)
      county_court_hearings

      
      charges_detail << [charge_data , county_court_hearings]
      charges_detail
    end
    charges_detail
  end

  def inmate_ids(booking_id, html)
    booking_id = booking_id.gsub("_", "/")
    page = Nokogiri::HTML(html)
    inmate_ids = {}
    inmate_ids[:arrestee_id] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[1].at('span').text if page.css('div[id="DemographicInformation"]').css('ul').css('li')[1].at('span').nil? == false 
    inmate_ids[:data_source_url] = fetch_data_url(booking_id)
    inmate_ids
  end

  def holding_facility(booking_id, booking)
    booking_id = booking_id.gsub("_", "/")
    facility = {}
    facility[:facility] = booking.at_css('.HousingFacility span').text if booking.at_css('.HousingFacility span').nil? == false 
    facility[:data_source_url] = fetch_data_url(booking_id)
    facility
  end

  def bonds(booking_id, booking)
    booking_id = booking_id.gsub("_", "/")
    bond_arr = []
    bonds_table = booking.at_css('.BookingBonds table')
    bonds_rows = bonds_table.css('tbody tr')
  
    bonds_rows.each do |bonds_row|
      bonds = {}
      bonds[:total_bond_amount] = booking.at_css('.TotalBondAmount span').text if booking.at_css('.TotalBondAmount span')
      bonds[:bond_number] = bonds_row.css('.BondNumber').text if bonds_row.css('.BondNumber')
      bonds[:bond_type] = bonds_row.css('.BondType').text if bonds_row.css('.BondType')
      bonds[:bond_amount] = bonds_row.css('.BondAmount').text if bonds_row.css('.BondAmount')
      bonds[:data_source_url] = fetch_data_url(booking_id)
  
      bond_arr << bonds
    end
    bond_arr
  end
  
  def fetch_data_url(booking_id)
    @persons_general[booking_id][:link]
  end
  
  def format_date(date_str)
    if date_str.empty? == false
      date = DateTime.strptime(date_str, "%m/%d/%Y %I:%M %p")
      formatted_date = date.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

end
