require 'date'

class Parser < Hamster::Parser

  def current_page(source)
    page = Nokogiri::HTML(source.body)

    @persons_general = {}

    page.css('tr')[1..].each do |tr|
      link = tr.css('a')[0]
      booking_id= link['href'].split('=')[-1]
      @persons_general[booking_id] =
        {
          name: link.content,
          link: 'http://inmate.kenoshajs.org' + link['href'],
        }
    end
    @persons_general
  end

  def give_current_page(source)
    page = Nokogiri::HTML source

    @persons_general = {}

    page.css('tr')[1..].each do |tr|
      link = tr.css('a')[0]
      booking_id= link['href'].split('=')[-1]
      @persons_general[booking_id] =
        {
          name: link.content,
          link: 'http://inmate.kenoshajs.org' + link['href'],
        }
    end
    @persons_general
  end

  def inmates(booking_id, html)
    booking_id = booking_id.gsub("_","/")
    page = Nokogiri::HTML html
    inmate = {}
    inmate[:full_name] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[0].at('span').text
    inmate[:race] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[4].at('span').text
    inmate[:sex] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[3].at('span').text
    inmate[:data_source_url] = @persons_general[booking_id][:link]
    inmate
  end

  def inmate_additional_info(booking_id, html)
    booking_id = booking_id.gsub("_","/")
    page = Nokogiri::HTML html
    inmate_additional_info = {}
    inmate_additional_info[:height] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[5].at('span').text
    inmate_additional_info[:weight] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[6].at('span').text
    inmate_additional_info[:age] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[2].at('span').text
    inmate_additional_info
  end

  def inmate_ids(booking_id, html)
    booking_id = booking_id.gsub("_","/")
    page = Nokogiri::HTML html
    inmate_ids = {}
    inmate_ids[:number] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[1].at('span').text
    inmate_ids[:type] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[1].attributes.values[0].value
    inmate_ids[:data_source_url] = @persons_general[booking_id][:link]
    inmate_ids
  end

  def inmate_addresses(booking_id, html)
    booking_id = booking_id.gsub("_","/")
    page = Nokogiri::HTML html
    inmate_addresses = {}
    inmate_addresses[:full_address] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[7].at('span').text
    address_length = page.css('div[id="DemographicInformation"]').css('ul').css('li')[7].at('span').text.split(",").count
    if address_length > 1
      inmate_addresses[:zip] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[7].at('span').text.split(",")[1].split(" ")[1]
      inmate_addresses[:state] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[7].at('span').text.split(",")[1].split(" ")[0]
      inmate_addresses[:city] = page.css('div[id="DemographicInformation"]').css('ul').css('li')[7].at('span').text.split(",")[0]
    else

    end
    inmate_addresses[:data_source_url] = @persons_general[booking_id][:link]
    inmate_addresses
  end

  def mugshots(booking_id, html)
    booking_id = booking_id.gsub("_","/")
    page = Nokogiri::HTML html
    mugshots = {}
    pict_acc = page.css('#Photos .BookingPhotos')[0]
    pict_link = pict_acc.at_css('img')['src'] if pict_acc.nil? == false
    mugshots[:data_source_url] = @persons_general[booking_id][:link]
    return pict_link , mugshots
  end

  def fetch_booking_details(booking_id, html)
    booking_id = booking_id.gsub("_","/")
    page = Nokogiri::HTML html
    bookings = page.css('div[class="Booking"]')
    booking_number = page.css('div[id="BookingHistory"]').at('span').text
    details_arr = []
    detail_arr = []
    bookings.each do |booking|
      arrest_data = arrests(booking_id, booking)	
      detail_arr << arrest_data
      bond_data = bonds(booking_id, booking)
      detail_arr << bond_data
      charge_data = charges(booking_id, booking)
      detail_arr << charge_data
      facility_data = holding_facility(booking_id, booking)
      detail_arr << facility_data
      arrests_additional_data = arrests_additional(booking_id, booking)
      detail_arr << arrests_additional_data
      bonds_additional_data = bonds_additoinal(booking_id, booking)
      detail_arr << bonds_additional_data
      detail_arr
    end
    details_arr << detail_arr
    details_arr
  end
  
  def arrests(booking_id, booking)
    arrest_date_str = booking.at_css('.BookingDate span').text
    formatted_date = format_date(arrest_date_str)
    arrests = {}
    arrests[:booking_number] = booking.at_css('h3 span').text
    arrests[:booking_date] = formatted_date
    arrests[:booking_agency] = booking.at_css('.BookingOrigin span').text
    arrests[:data_source_url] = @persons_general[booking_id][:link]
    
    arrests
  end
  
  def bonds(booking_id, booking)
    bonds = {}
    bonds[:bond_amount] = booking.at_css('.TotalBondAmount span').text
    bonds[:data_source_url] = @persons_general[booking_id][:link]
  
    bonds
  end

  def charges(booking_id, booking)
    charges_detail = []
    charges_table = booking.at_css('.BookingCharges table')
    charges_rows = charges_table.css('tbody tr')
  
    charges_rows.each do |charge|
      charge_date_str = charge.at_css('.DispositionDate').text if charge.at_css('.DispositionDate').nil? == false
      if charge_date_str.nil? == false && !charge_date_str.empty?
        charge_date = DateTime.strptime(charge_date_str, "%m/%d/%Y")
        formatted_date = charge_date.strftime("%Y-%m-%d")
      else
      end
      charge_data = {}
      charge_data[:docket_number] = charge.at_css('.DocketNumber').text if charge.at_css('.DocketNumber').nil? == false
      charge_data[:disposition] = charge.at_css('.Disposition').text if charge.at_css('.Disposition').nil? == false
      charge_data[:disposition_date] = formatted_date if formatted_date.nil? == false
      charge_data[:description] = charge.at_css('.ChargeDescription').text if charge.at_css('.ChargeDescription').nil? == false
      charge_data[:crime_class] = charge.at_css('.CrimeClass').text if charge.at_css('.CrimeClass').nil? == false
      charge_data[:attempt_or_commit] = charge.at_css('.AttemptCommit').text if charge.at_css('.AttemptCommit').nil? == false
      charge_data[:data_source_url] = @persons_general[booking_id][:link]
        
      charge_additonal_data = {}
      charge_additonal_data[:key] = "Arresting Agency"
      charge_additonal_data[:value] = charge.at_css('.ArrestingAgencies').text if charge.at_css('.ArrestingAgencies').nil? == false
      charge_additonal_data[:data_source_url] = @persons_general[booking_id][:link]
      
      charges_detail << [charge_data, charge_additonal_data]

    end
    charges_detail
  end

  def holding_facility(booking_id, booking)
    facility_date_str = booking.at_css('.ReleaseDate span').text
    formatted_date = format_date(facility_date_str)
    facility = {}
    facility[:actual_release_date] = formatted_date
    facility[:facility] = booking.at_css('.HousingFacility span').text
    facility[:data_source_url] = @persons_general[booking_id][:link]

    facility
  end

  def arrests_additional(booking_id, booking)
    arrests_additional = {}
    arrests_additional[:key] = booking.css('ul').css('li')[2].attributes.values[0].value.gsub(/(?<=[a-z])(?=[A-Z])/, ' ')
    arrests_additional[:value] = booking.at_css('.PrisonerType span').text
    arrests_additional[:key] = booking.css('ul').css('li')[3].attributes.values[0].value.gsub(/(?<=[a-z])(?=[A-Z])/, ' ').split(" ")[0]
    arrests_additional[:value] = booking.at_css('.ClassificationLevel span').text
    arrests_additional[:data_source_url] = @persons_general[booking_id][:link]

    arrests_additional
  end

  def bonds_additoinal(booking_id, booking)
    bonds_additoinal = {}
    bonds_additoinal[:key] = booking.css('ul').css('li')[6].attributes.values[0].value.gsub(/(?<=[a-z])(?=[A-Z])/, ' ')
    bonds_additoinal[:value] = booking.at_css('.TotalBailAmount span').text
    bonds_additoinal[:data_source_url] = @persons_general[booking_id][:link]

    bonds_additoinal
  end

  def format_date(date_str)
    if date_str.empty? == false
      date = DateTime.strptime(date_str, "%m/%d/%Y %I:%M %p")
      formatted_date = date.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

end
