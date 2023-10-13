# frozen_string_literal: true

require_relative '../lib/keeper'

class Parser < Hamster::Parser
  def initialize
    super
  end

  def get_table_of_records(source)
    page = Nokogiri::HTML source
    page.css('table')[1]
  end

  def parse_single_record(arr, data_source_url)
    name = arr[0].children[1].text #children[0] == record_number
    name_list = name.split
    first_name = name_list.shift
    middle_name = name_list.shift if name_list.size > 1
    last_name = name_list.join(' ') if !name_list.empty?
    law_firm_name = arr[1].text
    address1 = arr[2].text
    address2 = arr[3].text
    city_state_zip = arr[4].text

    addr_array = []
    addr_array.push(address1) if !address1.empty?
    addr_array.push(address2) if !address2.empty?
    addr_array.push(city_state_zip) if city_state_zip[0] != ','
    law_firm_address = addr_array.join(', ')

    city_separated = city_state_zip.split(', ')
    law_firm_city = city_separated[0] if !city_separated[0].empty?

    state_zip = city_separated[1].split
    law_firm_state = state_zip[0]
    law_firm_zip = state_zip[1]

    email = arr[6].text.split(': ')[1]
    phone = arr[7].text.split(': ')[1]
    fax = arr[8].text.split(': ')[1]
    registration_status = arr[10].text.split(': ')[1]
    bar_number = arr[11].text.split(': ')[1]

    date = arr[12].text.split(': ')[1]
    begin
      date_admited = Date.strptime(date, '%m/%d/%Y') if !!date
    rescue StandardError => e
      logger.warn(e)
    end

    record_data = {
      name:                 name.squeeze(" ").strip,
      first_name:           first_name,
      middle_name:          middle_name,
      last_name:            last_name,
      law_firm_name:        law_firm_name.squeeze(" ").strip,
      law_firm_address:     law_firm_address.squeeze(" ").strip,
      law_firm_city:        law_firm_city,
      law_firm_state:       law_firm_state,
      law_firm_zip:         law_firm_zip,
      email:                email,
      phone:                phone,
      fax:                  fax,
      registration_status:  registration_status,
      bar_number:           bar_number,
      date_admited:         date_admited,
      data_source_url:      data_source_url
    }
    digest_data = {
      name:                 name,
      law_firm_name:        law_firm_name,
      law_firm_address:     law_firm_address,
      email:                email,
      phone:                phone,
      fax:                  fax,
      registration_status:  registration_status,
      bar_number:           bar_number,
      date_admited:         date_admited
    }
    str = ""
    digest_data.each { |field| str += field.to_s if !!field }
    digest = Digest::MD5.new.hexdigest(str)
    record_data[:md5_hash] = digest

    record_data # return single record data
    # Keeper.new.store_record(record_data, run_id)
  end

  def parse_search_result(table, url)
    res = []
    arr = table.css('tr')
    1.upto(arr.size.div(16)) do |i| # loop every 16 <tr> per record
      start_pos = (i-1) * 16
      end_pos = start_pos + 15
      res << parse_single_record(arr[start_pos..end_pos], url)
    end
    res # return array of records
  end
end
