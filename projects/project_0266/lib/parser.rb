require_relative '../lib/scraper'

class Parser < Hamster::Parser

  def get_values(parsed_page)
    values =  parsed_page.css("input")
    view_state =values[-3]['value']
    view_state_version = values[-2]['value']
    view_state_mac = values[-1]['value']
    main_j_id0j_id61j_id62j_id64 = values[0]['value'] rescue nil
    [view_state, view_state_version, view_state_mac, main_j_id0j_id61j_id62j_id64]
  end

  def fetch_all_states(response)
    response.css('table').last.css('tr')[1].css('td').last.css('select').css('option').map(&:text)[1..]
  end

  def fetch_all_boards(response)
    response.css('table').last.css('tr')[-3].css('td').last.css('select').css('option').map(&:text)[1..]
  end

  def result_text(response)
    text = response.css('h4')
    text.empty? ? nil : text.last.text.strip
  end

  def source_count(result_text)
    result_text.split.first.to_i
  end

  def fetch_rows(response)
    response.css('table').last.css('tr')[1..]
  end

  def fetch_downloaded_links(response)
    all_rows = response.css('table').last.css('tr')[1..]
    all_rows.map { |s| s.css('td a').map { |e| e['href'] } }.flatten.map { |e| ('https://elicense.az.gov' + e) unless e.include? 'https://elicense.az.gov' }.flatten
  end

  def fetch_all_links(all_rows)
    all_rows.map { |s| s.css('td a').map { |e| e['href'] } }.flatten.map { |e| ('https://elicense.az.gov' + e) unless e.include? 'https://elicense.az.gov' }.flatten
  end

  def parse_data(data_page, link, run_id, type)
    data_hash = {}
    data_hash[:state]                   = search_values(data_page, 'State').downcase
    data_hash[:city]                    = search_values(data_page, 'City').downcase
    data_hash[:street]                  = search_values(data_page, 'Street')
    data_hash[:zip]                     = search_values(data_page, 'Zip Code')
    data_hash[:phone]                   = search_values(data_page, 'Phone')
    data_hash[:board]                   = search_values(data_page, "Board")
    data_hash[:license_number]          = search_values(data_page, 'License Number')
    data_hash[:license_type]            = search_values(data_page, 'License Type')
    data_hash[:issue_date]              = DateTime.strptime(search_values(data_page, 'Issue Date'), '%m/%d/%Y').to_date  rescue nil
    data_hash[:license_expiration_date] = DateTime.strptime(search_values(data_page, 'Expiration Date'), '%m/%d/%Y').to_date rescue nil
    data_hash[:status]                  = search_values(data_page, 'Status')
    if type == 'individual'
      name = get_name(data_page)
      data_hash[:full_name]             = name
      data_hash[:first_name]            = name.split(' ').first
      data_hash[:last_name]             = name.split(' ').last
    else type == 'business'
      data_hash[:business_name]         = get_name(data_page)
    end
    data_hash                           = mark_empty_as_nil(data_hash)
    md5_hash                            = create_md5_hash(data_hash)
    data_hash[:run_id]                  = run_id
    data_hash[:link]                    = link
    data_hash[:last_scrape_date]        = Date.today
    data_hash[:next_scrape_date]        = Date.today.next_week
    [data_hash , md5_hash]
  end

  def fetch_nokogiri_response(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  private

  def get_name(data_page)
    data_page.css("div.lcolumn").css("h1").text
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def search_values(data_page, search_text)
    values = data_page.css('small').select { |e| e.text.include? search_text.to_s }
    values[0].next_element.text.strip unless values.empty? rescue nil
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
