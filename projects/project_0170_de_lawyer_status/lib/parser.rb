# frozen_string_literal: true
class Parser < Hamster::Parser

  def get_body_data(response)
    page = parse_page(response)
    view_generator = page.css("#__VIEWSTATEGENERATOR").first["value"]
    viewstate = page.css("#__VIEWSTATE").first["value"]
    [view_generator, viewstate]
  end

  def pagination_body(response)
    parse_page(response).css('text()').select{|e| e.text.size > 150}.first
  end

  def parse(response, run_id)
    page = parse_page(response)
    hash_array = []
    page.css('table#VwPublicSearchTableControlGrid tr')[1..-1].each do |row|
      data_hash = {}
      city_state                      = row.css('td')[1].text.split("\r\n") 
      firm                            = row.css('td')[1].text.squish
      name_check                      = row.css('td')[1].text.squish.split
      city, state, name               = find_firm_info(firm, name_check, city_state)
      data_hash[:name]                = row.css('td')[0].text.squish rescue nil
      data_hash[:bar_number]          = row.css('td')[3].text.squish rescue nil
      data_hash[:law_firm_name]       = name
      data_hash[:law_firm_city]       = ((city.nil?) || (city.include? 'NA')) ? nil : city
      data_hash[:law_firm_state]      = state
      phone = row.css('td')[2].text.squish rescue nil
      data_hash[:phone]               = phone.count("a-zA-Z") > 0 ? nil : phone
      data_hash[:date_admitted]       = row.css('td')[4].text.squish rescue nil
      data_hash[:date_admitted]       = Date.strptime(data_hash[:date_admitted] , "%m/%d/%Y") rescue nil
      data_hash[:registration_status] = row.css('td')[5].text.squish rescue nil
      data_hash                       = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash]            = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id

      hash_array.append(data_hash)
    end
    hash_array
  end

  def get_page_value(response)
    parse_page(response).css("#ctl00_PageContent_Pagination__CurrentPage")[0]["value"].to_i
  end

  private

  def find_firm_info(firm, name_check, city_state)
    return [] if firm == 'N/A' || firm == 'NONE' || firm == 'NA' || firm.empty?
    city  = get_value(get_index(city_state[1]), city_state).squish rescue nil
    state = get_value(get_index(city_state[1]) + 1, city_state).squish rescue nil
    name  = (name_check[0] == 'N/A' || name_check[0] == 'NA' || name_check[0] == 'NONE' || city_state[0].squish.empty? || name_check[0] == '.')? nil : city_state[0].squish
    [city, state, name]
  end

  def get_index(value)
    value =="" ? 2: 1
  end

  def get_value(index, city_state)
    (city_state[index].squish == 'NA' || city_state[index].squish == 'N/A' || city_state[index].squish == 'N/' || city_state[index].squish.empty? || city_state[index].squish == '--' || city_state[index].squish == '0000' ? nil : city_state[index])
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value.to_s.squish}
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
