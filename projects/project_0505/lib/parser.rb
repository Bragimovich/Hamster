require_relative '../lib/message_send'
require_relative '../lib/keeper'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    data_source = body.css('.original_link').text
    main_content = body.css('#MainContent')
    title_table = main_content.css('.ssJailingDetailTitle')
    booking_number = title_table.blank? ? nil : title_table.css('tr')[0].css('td')[0].text
    booking_number = booking_number.blank? ? nil : booking_number.gsub('Booking #:','').strip
    booking_agency = title_table.blank? ? nil : title_table.css('tr')[0].css('td')[1].text
    facility = title_table.blank? ? nil : title_table.css('tr')[1].css('td')[0].text
    facility = facility.blank? ? nil : facility.gsub('Facility:','').strip
    facility = nil if facility.blank?
    booked = title_table.blank? ? nil : title_table.css('tr')[1].css('td')[1].text
    booked = booked.blank? ? nil : booked.gsub('Booked:','').strip
    booked = booked.blank? ? nil : Date.strptime(booked,'%m/%d/%Y')
    released = title_table.blank? ? nil : title_table.css('tr')[1].css('td')[2].text
    released = released.blank? ? nil : released.gsub('Released:','').strip
    released = released.blank? ? nil : Date.strptime(released,'%m/%d/%Y')
    detail_table = main_content.css('.ssJailingDetail')
    name = detail_table.css('tr')[0].css('td')[1].text
    race = detail_table.css('tr')[0].css('td')[3].css('span')[0].text
    race = race.blank? ? nil : race.strip.gsub(/\s/,' ').gsub(' ',' ').squeeze(' ').strip
    sex = detail_table.css('tr')[0].css('td')[3].css('span')[1].text
    sex = sex.blank? ? nil : sex.strip.gsub(/\s/,' ').gsub(' ',' ').squeeze(' ').strip
    height = detail_table.css('tr')[0].css('td')[3].css('span')[2].text
    height = height.blank? ? nil : height.gsub(/\s/,' ').gsub(' ',' ').squeeze(' ').strip
    weight = detail_table.css('tr')[0].css('td')[3].css('span')[3].text
    weight = weight.blank? ? nil : weight.gsub(/\s/,' ').gsub(' ',' ').squeeze(' ').strip
    aliases = detail_table.css('tr')[1].css('td')[1].text
    aliases = aliases.blank? ? [] : aliases.split(';').map{|i| i.strip}
    so_number = detail_table.css('tr')[2].css('td')[1].text
    birth_date = detail_table.css('tr')[3].css('td')[1].text
    birth_date = birth_date.blank? ? nil : Date.strptime(birth_date,'%m/%d/%Y')
    address = detail_table.css('tr')[4].css('td')[1].text
    if address.blank? || !address.include?(',')
      city = nil
      state = nil
      zip = nil
    else
      address_arr = address.split(',')
      city = address_arr[0].strip
      state = address_arr[1].strip.split(' ')[0].strip
      zip = address_arr[1].strip.split(' ')[1].strip
    end
    photos = main_content.css('table')[1].css('tr')[0].css('td')[-1].css('img')
    photos = photos.to_a.map{|img| "https://portal-ilchampaign.tylertech.cloud/JailSearch/#{img['src']}"}
    charges_table = main_content.css('table')[3].css('tr')
    inx = 0
    charges = []
    charges_table.each do |tr|
      inx += 1
      next if inx < 3
      charge = tr.css('td')[1].text
      offense_date = tr.css('td')[3].text
      offense_date = offense_date.blank? ? nil : Date.strptime(offense_date,'%m/%d/%Y')
      bond = tr.css('td')[4]
      if bond.text.blank?
        bond_type = nil
        bond_amount = nil
      else
        bond_type = bond.css('div')[1].text
        bond_amount = bond.css('div')[0].text
      end
      disposition = tr.css('td')[6].text
      charges << {
        charge: charge,
        offense_date: offense_date,
        bond_type: bond_type,
        bond_amount: bond_amount,
        disposition: disposition
      }
    end
    inmate = {
      full_name: name,
      birthdate: birth_date,
      race: race,
      sex: sex,
      height: height,
      weight: weight,
      so_number: so_number,
      full_address: address,
      city: city,
      state: state,
      zip: zip,
      aliases: aliases,
      booking_number: booking_number,
      booking_agency: booking_agency,
      booking_date: booked,
      release_date: released,
      facility: facility,
      charges: charges,
      mugshots: photos,
      data_source_url: data_source
    }
    inmate
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def viewstate(hamster_search)
    Nokogiri::HTML.parse(hamster_search.body).css('#__VIEWSTATE')[0]['value']
  end

  def viewstategenerator(hamster_search)
    Nokogiri::HTML.parse(hamster_search.body).css('#__VIEWSTATEGENERATOR')[0]['value']
  end

  def eventvalidation(hamster_search)
    Nokogiri::HTML.parse(hamster_search.body).css('#__EVENTVALIDATION')[0]['value']
  end

  def profile_links(hamster_search_post)
    Nokogiri::HTML.parse(hamster_search_post.body).css('body > table')[3].css('tr')[2].css('td > a')
  end

  def body_content(hamster_profile)
    Nokogiri::HTML.parse(hamster_profile.body).to_s
  end
end
