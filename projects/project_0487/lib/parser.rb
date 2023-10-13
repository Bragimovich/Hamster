require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def links(hamster)
    content = Nokogiri::HTML.parse(hamster.body).css('.Results .Grid table tbody')
    profiles = []
    return if content.text.strip.include? 'No data'
    content.css('tr').to_a.each do |item|
      profile = item.css('.Name a')[0]['href']
      profile = 'http://inmate.co.kendall.il.us' + profile
      profiles << profile
    end
    profiles
  end

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    data_source_url = body.css('.original_link').text
    full_name = body.css('#DemographicInformation .Name span').text
    return if full_name.blank?
    full_name = nil if full_name.blank?
    number = body.css('#DemographicInformation .SubjectNumber span').text
    number = number.blank? ? nil : number.strip
    age = body.css('#DemographicInformation .Age span').text
    age = age.blank? ? nil : age.strip
    sex = body.css('#DemographicInformation .Gender span').text
    sex = sex.blank? ? nil : sex.strip
    race = body.css('#DemographicInformation .Race span').text
    race = race.blank? ? nil : race.strip
    height = body.css('#DemographicInformation .Height span').text
    height = height.blank? ? nil : height.strip
    weight = body.css('#DemographicInformation .Weight span').text
    weight = weight.blank? ? nil : weight.strip
    full_address, street_address, city, state, zip = address(body)
    aliases = body.css('#DemographicInformation .Aliases span').text.squeeze(',').split(',')
    aliases = aliases.blank? ? [] : aliases.map { |item| item.blank? ? nil : item.strip }
    mugshots = mugshots(body)
    bookings = bookings(body)
    inmate = {
      data_source_url: data_source_url,
      full_name: full_name,
      number: number,
      age: age,
      sex: sex,
      race: race,
      height: height,
      weight: weight,
      full_address: full_address,
      street_address: street_address,
      city: city,
      state: state,
      zip: zip,
      aliases: aliases,
      mugshots: mugshots,
      bookings: bookings
    }
    inmate
  end

  def mugshots(body)
    mugshots = body.css('#Photos .BookingPhotos a')
    mugshots_arr = []
    mugshots.each do |mugshot|
      mugshot_original = 'http://inmate.co.kendall.il.us' + mugshot[:href]
      mugshot_notes = mugshot.css('span').text
      mugshot_notes = mugshot_notes.blank? ? nil : mugshot_notes.strip
      mugshots_arr << { mugshot_original: mugshot_original, mugshot_notes: mugshot_notes }
    end
    mugshots_arr
  end
  def address(body)
    street_address = body.css('#DemographicInformation .Address .Street').text
    city_state = body.css('#DemographicInformation .Address .CityState').text
    if street_address.blank?
      full_address = city_state
    elsif city_state.blank?
      full_address = street_address
    else
      full_address = "#{street_address.strip}, #{city_state.strip}"
    end
    if city_state.include?(',')
      city = city_state.split(',')[0].strip
      state = city_state.split(',')[1].strip.split(' ')
      state.pop if city_state.match? /\d/
      state = state.join(' ')
      zip = city_state.split(',')[1].strip.split(' ')[-1]
      zip = zip.match?(/\d/) ? zip : nil
    else
      city = nil
      state = nil
      zip = nil
    end
    full_address = full_address.blank? ? nil : full_address.strip
    street_address = street_address.blank? ? nil : street_address.strip
    city = city.blank? ? nil : city.strip
    state = state.blank? ? nil : state.strip
    zip = zip.blank? ? nil : zip.strip
    [full_address,street_address,city,state,zip]
  end

  def bookings(body)
    bookings = body.css('#BookingHistory .Booking')
    bookings_arr = []
    bookings.each do |booking|
      booking_number = booking.css('h3 span').text
      booking_number = booking_number.blank? ? nil : booking_number.strip
      booking_date = booking.css('.BookingData .BookingDate span').text
      booking_date = booking_date.blank? ? nil : booking_date.split(' ')[0].strip
      booking_date = booking_date.blank? ? nil : Date.strptime(booking_date,'%m/%d/%Y')
      actual_release_date = booking.css('.BookingData .ReleaseDate span').text
      actual_release_date = actual_release_date.blank? ? nil : actual_release_date.split(' ')[0].strip
      actual_release_date = actual_release_date.blank? ? nil : Date.strptime(actual_release_date,'%m/%d/%Y')
      planned_release_date = booking.css('.BookingData .ScheduledReleaseDate span').text
      planned_release_date = planned_release_date.blank? ? nil : planned_release_date.split(' ')[0].strip
      planned_release_date = planned_release_date.blank? ? nil : Date.strptime(planned_release_date,'%m/%d/%Y')
      booking_agency = booking.css('.BookingData .BookingOrigin span').text
      booking_agency = booking_agency.blank? ? nil : booking_agency.strip
      facility = booking.css('.BookingData .HousingFacility span').text
      facility = facility.blank? ? nil : facility.strip
      total_bond = amount_clean(booking.css('.BookingData .TotalBondAmount span').text)
      total_bond = nil if total_bond.blank?
      total_bail = amount_clean(booking.css('.BookingData .TotalBailAmount span').text)
      total_bail = nil if total_bail.blank?
      booking_charges = booking_charges(booking)
      booking_court_info = booking_court_info(booking)
      booking_bonds = booking_bonds(booking)
      bookings_arr << {
        booking_number: booking_number,
        booking_date: booking_date,
        actual_release_date: actual_release_date,
        planned_release_date: planned_release_date,
        booking_agency: booking_agency,
        facility: facility,
        total_bond: total_bond,
        total_bail: total_bail,
        booking_charges: booking_charges,
        booking_court_info: booking_court_info,
        booking_bonds: booking_bonds
      }
    end
    bookings_arr
  end

  def booking_charges(booking)
    charges = booking.css('.BookingCharges .Grid table tbody tr')
    charges_arr = []
    unless charges.text.strip == 'No data'
      charges.each do |charge|
        charge_number = charge.css('.SeqNumber').text
        charge_number = charge_number.blank? ? nil : charge_number.strip
        description = charge.css('.ChargeDescription').text
        description = description.blank? ? nil : description.strip
        offense_date_time = charge.css('.OffenseDate').text.split(' ')
        offense_date = offense_date_time[0]
        offense_date_time.shift(1)
        offense_time = offense_date_time.join(' ')
        offense_date = offense_date.blank? ? nil : Date.strptime(offense_date,'%m/%d/%Y')
        offense_time = offense_time.blank? ? nil : Time.strptime(offense_time,'%l:%M %p')
        crime_class = charge.css('.CrimeClass').text
        crime_class = crime_class.blank? ? nil : crime_class.strip
        docker_number = charge.css('.DocketNumber').text
        docker_number = docker_number.blank? ? nil : docker_number.strip
        disposition = charge.css('.Disposition').text
        disposition = disposition.blank? ? nil : disposition.strip
        disposition_date = charge.css('.DispositionDate').text
        disposition_date = disposition_date.blank? ? nil : disposition_date.strip
        disposition_date = disposition_date.blank? ? nil : Date.strptime(disposition_date,'%m/%d/%Y')
        attempt_or_commit = charge.css('.AttemptCommit').text
        attempt_or_commit = attempt_or_commit.blank? ? nil : attempt_or_commit.strip
        bond_number = charge.css('.ChargeBond').text
        bond_number = bond_number.blank? ? nil : bond_number.strip
        charges_arr << {
          charge_number: charge_number,
          description: description,
          offense_date: offense_date,
          offense_time: offense_time,
          crime_class: crime_class,
          docker_number: docker_number,
          disposition: disposition,
          disposition_date: disposition_date,
          attempt_or_commit: attempt_or_commit,
          bond_number: bond_number
        }
      end
    end
    charges_arr
  end

  def booking_court_info(booking)
    court_infos = booking.css('.BookingCourtInfo .Grid table tbody tr')
    court_infos_arr = []
    unless court_infos.text.strip == 'No data'
      court_infos.each do |court_info|
        charges = court_info.css('.Charges').text.split(',').map {|item| item.strip}
        court_date_time = court_info.css('.CourtDate').text.split(' ')
        court_date = court_date_time[0]
        court_date = court_date.blank? ? nil : Date.strptime(court_date,'%m/%d/%Y')
        court_date_time.shift(1)
        court_time = court_date_time.join(' ')
        court_time = court_time.blank? ? nil : Time.strptime(court_time,'%l:%M %p')
        court = court_info.css('.Court').text
        court = court.blank? ? nil : court.strip
        court_room = court_info.css('.CourtRoom').text
        court_room = court_room.blank? ? nil : court_room.strip
        court_infos_arr << {
          charges: charges,
          court_date: court_date,
          court_time: court_time,
          court: court,
          court_room: court_room
        }
      end
    end
    court_infos_arr
  end

  def booking_bonds(booking)
    bonds = booking.css('.BookingBonds .Grid table tbody tr')
    bonds_arr = []
    unless bonds.text.strip == 'No data'
      bonds.each do |bond|
        bond_number = bond.css('.BondNumber').text
        bond_number = bond_number.blank? ? nil : bond_number.strip
        bond_type = bond.css('.BondType').text
        bond_type = bond_type.blank? ? nil : bond_type.strip
        bond_amount = amount_clean(bond.css('.BondAmount').text)
        bond_amount = nil if bond_amount.blank?
        bonds_arr << {
          bond_number: bond_number,
          bond_type: bond_type,
          bond_amount: bond_amount
        }
      end
    end
    bonds_arr
  end

  def amount_clean(amount)
    if amount.blank?
      nil
    else
      amount.gsub(/\..*$/, '').gsub(/\D/, '').to_i
    end
  end
end