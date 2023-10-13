# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    @hash = nil
    @data_source_url = nil
    super
  end

  def inmate_ids(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    inmate_data = []
    parsed_doc.xpath("//table/tbody/tr").each do |tr|
      next unless tr.at_xpath("./td[1]/a/@href")

      inmate_data << {
        href: tr.at_xpath("./td[1]/a/@href")&.value,
        name: tr.at_xpath("./td[1]")&.text&.presence,
        subject_number: tr.at_xpath("./td[2]")&.text&.presence,
        in_custody: tr.at_xpath("./td[3]")&.text&.presence,
        multiple_bookings: tr.at_xpath("./td[4]")&.text&.presence,
        housing_facility: tr.at_xpath("./td[5]")&.text&.presence
      }
    end
    inmate_data
  end

  def parse_detail_page(response_body, data_source_url, data)
    @hash = {}
    @data_source_url = data_source_url
    @inmate_id = data[:subject_number]
    parsed_doc = Nokogiri::HTML.parse(response_body)
    @hash['arrest_data'] = []
    status_data(data)
    inmate_data(data)
    inmate_id_data(data)
    additional_data(data)
    parsed_doc.xpath("//div[@class='Booking']").each do |booking_tag|
      @hash['arrest_data'] << arrest_data(booking_tag)
    end
    @hash.dup
  end

  def status_data(data)
    return unless data[:in_custody].presence

    @hash['WaSnohomishInmateStatus'] = {
      data_source_url: @data_source_url,
      status: 'In Custody',
      date_of_status_change: Date.today
    }
  end

  def inmate_data(data)
    @hash['WaSnohomishInmate'] = {
      data_source_url: @data_source_url,
      full_name: data[:name],
      last_name: data[:name].split(', ').first,
      first_name: data[:name].split(', ').last
    }
  end

  def inmate_id_data(data)
    @hash['WaSnohomishInmateId'] = {
      type: 'Subject Number',
      number: @inmate_id,
      data_source_url: @data_source_url
    }
  end

  def additional_data(data)
    return unless data[:in_custody].presence

    @hash['WaSnohomishInmateAdditionalInfo'] = {
      current_location: data[:housing_facility].presence,
      data_source_url: @data_source_url
    }
  end

  def arrest_data(booking_tag)
    @booking_bond_rows = booking_tag.xpath("./div/div[@class='BookingBonds']/div/table/tbody/tr").map{|tr| tr.xpath("./td").map(&:text)}
    @booking_court_rows = booking_tag.xpath("./div/div[@class='BookingCourtInfo']/div/table/tbody/tr").map{|tr| tr.xpath("./td").map(&:text)}
    booking_data = {}
    bd = booking_tag.at_xpath("./div/ul/li[@class='BookingDate']/span")&.text&.presence
    bd = DateTime.strptime(bd, '%m/%d/%Y %H:%M %p') rescue nil
    booking_data = {
      data_source_url: @data_source_url,
      booking_number: booking_tag.at_xpath("./h3/span")&.text&.presence,
      booking_date: bd,
      booking_agency: booking_tag.at_xpath("./div/ul/li[@class='BookingOrigin']/span")&.text&.presence,
      holding_data: holding_data(booking_tag),
      charges_data: charges_data(booking_tag)
    }
    booking_data
  end

  def holding_data(booking_tag)
    actual_release_date = booking_tag.at_xpath("./div/ul/li[@class='ReleaseDate']/span")&.text&.presence
    actual_release_date = DateTime.strptime(actual_release_date, '%m/%d/%Y %H:%M %p') rescue nil
    {
      data_source_url: @data_source_url,
      actual_release_date: actual_release_date,
      facility: booking_tag.at_xpath("./div/ul/li[@class='HousingFacility']/span")&.text&.presence
    }
  end

  def charges_data(booking_tag)
    data = []
    booking_tag.xpath("./div/div[@class='BookingCharges']/div/table/tbody/tr").each do |tr|
      if tr.xpath('./td').count < 10
        logger.info "booking tag has error, url => #{@data_source_url}"

        next
      end
      dd = tr.at_xpath('./td[8]').text.presence
      dd = Date.strptime(dd, '%m/%d/%Y') rescue nil
      od = tr.at_xpath('./td[4]').text.presence
      od = DateTime.strptime(od, '%m/%d/%Y %H:%M %p') rescue nil
      data << {
        data_source_url: @data_source_url,
        number: tr.at_xpath('./td[1]').text.presence,
        docket_number: tr.at_xpath('./td[5]').text.presence,
        disposition: tr.at_xpath('./td[7]').text.presence,
        disposition_date: dd,
        description: tr.at_xpath('./td[2]').text.presence,
        counts: tr.at_xpath('./td[3]').text.presence,
        offense_date: od,
        offense_time: od,
        crime_class: tr.at_xpath('./td[10]').text.presence,
        additional_data: charges_additional_data(tr),
        bond_data: bond_data(tr),
        hearing_data: hearing_data(tr)
      }
    end
    data
  end

  def charges_additional_data(tr)
    data = []
    if tr.at_xpath('./td[6]').text.presence
      data << {
        data_source_url: @data_source_url,
        key: 'Sentence Date',
        value: tr.at_xpath('./td[6]').text
      }
    end
    if tr.at_xpath('./td[11]').text.presence
      data << {
        data_source_url: @data_source_url,
        key: 'Arresting Agency',
        value: tr.at_xpath('./td[11]').text
      }
    end
    data
  end

  def bond_data(tr)
    data = []
    bond_number = tr.at_xpath('./td[12]').text.presence
    return data unless bond_number

    bond_number.split(', ').each do |bn|
      bond_row = @booking_bond_rows.select{|tr| tr[0] == bn}.first
      data << {
        data_source_url: @data_source_url,
        bond_number: bond_number,
        bond_type: 'Bond',
        bond_amount: bond_row[2].presence,
        paid_status: bond_row[3].presence
      }
    end
    data
  end

  def hearing_data(tr)
    data       = []
    number     = tr.at_xpath('./td[1]').text.presence
    court_rows = @booking_court_rows.select{|tr| tr[0].include?(number)}
    court_rows.each do |court_row|
      court_date = DateTime.strptime(court_row[1], '%m/%d/%Y %H:%M %p') rescue nil
      data << {
        data_source_url: @data_source_url,
        court_date: court_date,
        court_time: court_date,
        court_name: court_row[2].presence,
        court_room: court_row[3].presence,
        sentence_length: tr.at_xpath('./td[9]').text.presence
      }
    end
    data
  end
end
