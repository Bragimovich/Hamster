# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_site_agency_json(json)
    cfg = parse_json(json)
    site_ref   = cfg['siteRefId']
    agency_ref = cfg['agencyRefId']
    if site_ref.nil? || agency_ref.nil?
      logger.info 'Failed to parse agency JSON.'
      logger.info json
      raise 'Failed to parse agency JSON.'
    end

    { site_ref: site_ref, agency_ref: agency_ref }
  end

  def parse_inmate_details(inmate_html)
    doc = Nokogiri::HTML(inmate_html)
    rows = doc.xpath('//table[@summary="Result."]/tr')

    inmate = {}
    rows.each do |row|
      cols = row.xpath('td')
      next unless cols.size == 2

      label = cols[0].inner_text&.strip
      value = cols[1].inner_text&.strip
      case label
      when 'Status:'
        inmate[:status] = value
      when 'Bond Amount:'
        inmate[:bond_amount] = value
      when 'Date of Sentence:'
        inmate[:booking_date] = parse_date(value)
      when 'Maximum Release Date:'
        inmate[:max_release_date] = value
      when 'Estimated Release Date:'
        inmate[:planned_release_date] = parse_date(value)
      when 'Special Parole End Date:'
        inmate[:parole_date] = parse_date(value)
      end
    end

    inmate
  end

  def parse_inmate_list(list_html)
    doc = Nokogiri::HTML(list_html)
    rows = doc.xpath('//table[@summary="Result."]/tr')
    rows.map do |row|
      cols = row.xpath('td')
      next nil unless cols.size == 4

      {
        birthdate:     parse_date(cols[2].inner_text&.strip),
        full_name:     cols[1].inner_text&.strip,
        inmate_number: cols[0].inner_text&.strip,
        facility:      cols[3].inner_text&.strip
      }
    end
    .compact
  end

  def parse_site_agency(inmate_html)
    match_data = inmate_html.match(/https:\/\/www\.vinelink\.com\/vinelink\/servlet\/SubjectSearch\?siteID=(\d*)&agency=(\d*)&offenderID=\{0\}/)
    if match_data.size == 3
      site_id   = match_data[1].to_i
      agency_id = match_data[2].to_i
      return [site_id, agency_id] unless site_id.zero? || agency_id.zero?
    end

    logger.info 'Failed to parse site and agency info.'
    logger.info inmate_html
    raise 'Failed to parse site and agency info.'
  end

  def parse_vine_json(json)
    vine_obj = parse_json(json)
    persons = vine_obj.dig('_embedded', 'persons')
    if persons.nil?
      logger.info 'Failed to parse Vine JSON.'
      logger.info json
      raise 'Failed to parse Vine JSON.'
    end

    result = {}

    person = persons.first
    return result if person.nil?

    result[:photo_link]  = person.dig('_links', 'desktopImage', 'href')
    result[:first_name]  = person.dig('personName', 'firstName')
    result[:middle_name] = person.dig('personName', 'middleName')
    result[:last_name]   = person.dig('personName', 'lastName')

    locations = person['locations']
    unless locations.nil?
      rep_agcy = locations.find { |loc| loc['locationType'] == 'REPORTING_AGENCY' }
      unless rep_agcy.nil?
        loc_name  = rep_agcy['locationName']
        loc_addr  = rep_agcy.dig('locationStreetAddress', 'street')
        loc_city  = rep_agcy.dig('locationStreetAddress', 'city')
        loc_state = rep_agcy.dig('locationStreetAddress', 'state', 'code')
        loc_zip   = rep_agcy.dig('locationStreetAddress', 'postalCode')
        loc_phone = rep_agcy['locationPhone']
        state_zip = [loc_state, loc_zip].compact.join(' ')

        result[:booking_agency] = [loc_name, loc_addr, loc_city, state_zip, loc_phone].compact.join(', ')
      end

      facility = locations.find { |loc| loc['locationType'] == 'HOLDING_FACILITY' }
      unless facility.nil?
        loc_name  = facility['locationName']
        loc_addr  = facility.dig('locationStreetAddress', 'street')
        loc_city  = facility.dig('locationStreetAddress', 'city')
        loc_state = facility.dig('locationStreetAddress', 'state', 'code')
        loc_zip   = facility.dig('locationStreetAddress', 'postalCode')
        loc_phone = facility['locationPhone']
        state_zip = [loc_state, loc_zip].compact.join(' ')

        result[:fac_full]  = [loc_name, loc_addr, loc_city, state_zip, loc_phone].compact.join(', ')
        result[:fac_addr]  = loc_addr
        result[:fac_city]  = loc_city
        result[:fac_state] = loc_state
        result[:fac_zip]   = loc_zip
      end
    end

    result
  end

  private

  def parse_date(date_string)
    dt = Date.strptime(date_string, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
    dt ||= Date.strptime(date_string, '%m/%d/%Y').strftime('%Y-%m-%d') rescue nil
    dt
  end

  def parse_json(json)
    JSON.parse(json)
  rescue => e
    logger.info 'Failed to parse JSON.'
    logger.info json
    raise e
  end
end
