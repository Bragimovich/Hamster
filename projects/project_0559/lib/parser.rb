class Parser < Hamster::Parser

  def parsing(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def fetch_states(page)
    page.css("label").select{|e| e.text.strip == 'State:'}.first.next_element.css("option").map(&:text)[1..-1]
  end

  def get_main_body(page)
    vs  = page.css("span")[4].children[0]['value']
    vs_version = page.css("span")[4].children[1]['value']
    vs_mac = page.css("span")[4].children[2]['value']
    [vs, vs_version, vs_mac]
  end

  def get_page_body(page)
    vs  = page.css("#ajax-view-state").children[0]['value']
    vs_version = page.css("#ajax-view-state").children[1]['value']
    vs_mac = page.css("#ajax-view-state").children[2]['value']
    [vs, vs_version, vs_mac]
  end

  def next_btn(page)
    page.css('a[title="Next Page"]').empty? ? true : false
  end

  def get_data(file_data, run_id, licence_board, link, state)
    parsed_data = parsing(file_data)
    data_set = parsed_data.css('div.col-md-9 .form-group')
    return nil if link.include? 'ComplaintPage'
    data_hash = {}
    data_hash[:licensing_board]                                                               = licence_board
    data_hash[:licensee]                                                                      = parsed_data.css("h1")[1].text
    data_hash[:address_street]                                                                = search_data(data_set, 'License Street')
    data_hash[:address_city], data_hash[:address_state], data_hash[:address_zip_postal_code]  = splitting(search_data(data_set, 'License City, State, Zip'), state)
    data_hash[:firm_name]                                                                     = search_data(data_set, 'Firm Name')
    data_hash[:number]                                                                        = search_data(data_set, 'Number')
    data_hash[:license_type]                                                                  = search_data(data_set, 'License Type')
    data_hash[:license_status]                                                                = search_data(data_set, 'License Status')
    data_hash[:expiration_date]                                                               = search_data(data_set, 'Expiration Date')
    data_hash[:original_created_date]                                                         = search_data(data_set, 'Original Created Date')
    data_hash[:reinstate_date]                                                                = search_data(data_set, 'Reinstate Date')
    data_hash[:last_status_change_date]                                                       = search_data(data_set, 'Last Status Change Date')
    data_hash[:renewed_date]                                                                  = search_data(data_set, 'Renewed Date')
    data_hash[:conversion_date]                                                               = search_data(data_set, 'Conversion Date')
    data_hash                                                                                 = date_setting(data_hash)
    data_hash                                                                                 = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]                                                                      = create_md5_hash(data_hash)
    data_hash[:run_id]                                                                        = run_id
    data_hash[:touched_run_id]                                                                = run_id
    data_hash[:data_source_url]                                                               = link
    data_hash
  end

  def links(page)
    page.css(".trRecord td a").map { |e| "https://ia-plb.my.site.com" + e["href"] }
  end

  def licensing_board(page)
    page.css(".trRecord").map{|a| a.css("td")[3].text.squish}
  end

  private

  def search_data(data_set, key)
    data_set.select { |e| e.text.include? key}[0].css('p').text.squish rescue nil
  end

  def date_setting(data_hash)
    data_hash.keys.each do |key|
      data_hash[key] = (data_hash[key] == "//") ? "" : data_hash[key]
      next unless ((key.to_s.include? "date") && !(data_hash[key].empty?))
      value = data_hash[key]
      array = value.split("/")
      if (array[2].size == 2)
        array[2] = (2000 + array[2].to_i).to_s
        data_hash[key] = array.join("/")
      end
      data_hash[key] = DateTime.strptime(data_hash[key],"%m/%d/%Y").to_date
    end
    data_hash
  end

  def splitting(row_data, state)
    if row_data.split(",").last.split.select{|e| e.to_i != 0}.count > 0
      zip = row_data.split(",").last.split.select{|e| e.to_i != 0}.first
      city = row_data.split(",").first.squish
      state = row_data.split(",").last.split(zip).first.squish
    else
      zip = row_data.split.map(&:squish).last
      city = row_data.split(",").first.squish
      state = row_data.split(",").last.split(zip).first.squish
    end
    state = set_state(state)
    [city, state, zip]
  end

  def set_state(state)
    state.scan(/\w+/).reject{|e| e if !e.scan(/\d+/).empty?}.join(" ")
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| (value.to_s == " ") || (value == 'null') || (value == '') ? nil : value }
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
