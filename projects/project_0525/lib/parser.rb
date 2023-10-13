class Parser < Hamster::Parser

  def parser(html, file, run_id, already_inserted_md5_hashes, run_id_update_array)
    data_array = []
    data = Nokogiri::HTML(html.force_encoding('utf-8'))
    data = data.css('#LawyerSearchResults section.LawyerInformation')
    data.each do |record|
      data_hash = {}

      data_hash[:name] = search_value(record ,"Name:")
      
      data_hash[:law_firm_name] = search_value(record ,"Company:")
      data_hash[:date_admited] = Date.strptime(search_value(record ,"Admit Date:"),'%m/%d/%Y') rescue nil
      data_hash[:complete_physical_address] = search_value(record ,"Physical Address:")
      data_hash[:complete_mailing_address] = search_value(record ,"Mailing Address:")

      data_hash[:physcial_address], data_hash[:physcial_address_city], data_hash[:physcial_address_state], data_hash[:physcial_address_zip] = fetch_address(data_hash[:complete_physical_address])

      data_hash[:mailing_address], data_hash[:mailing_address_city], data_hash[:mailing_address_state], data_hash[:mailing_address_zip] = fetch_address(data_hash[:complete_mailing_address])

      data_hash[:phone] = search_value(record ,"Phone:")
      data_hash[:email] = search_value(record ,"Email:")
      data_hash[:fax] = search_value(record ,"Fax:")
      data_hash[:registration_status] = search_value(record ,"Status:")

      md5_hash = create_md5_hash(data_hash)

      if already_inserted_md5_hashes.include? md5_hash
        run_id_update_array << md5_hash
        already_inserted_md5_hashes.delete md5_hash
        next
      end

      data_hash[:data_source_url] = "https://www.msbar.org/lawyer-directory/?type=7&term=#{file.gsub('.gz', '')}"
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array << data_hash
    end
    [data_array, already_inserted_md5_hashes, run_id_update_array]
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def fetch_address(address)
    return [nil, nil, nil, nil] if address.nil?
    return [address, nil, nil, nil] if address.split("\n").count == 1
    data = address.split("\n").last.split(',')
    return  [address, nil, nil, nil] if (data[0].include? 'No address available' or data[0].include? 'Address not public')
    return [address + ' ' + data[0], nil, nil, nil] if data.count == 1
    address_main = address.split("\n")[0..-2].join("\n")
    city  = data[0]
    state = data[1].split(' ')[0]
    zip   = data[1].split(' ')[1]
    state, zip = state_fix(state, zip)
    [address_main, city, state, zip]
  end

  def state_fix(state, zip)
    unless state.to_i == 0
      zip = state
      state = nil
    end
    [state, zip]
  end

  def search_value(record, word)
    value = nil
    search_result = record.css('div').select {|d| d.text.squish == word}
    return  nil if search_result.empty?
    return search_result[0].next_element.text.squish unless search_result[0].text.include? "Address"
    search_result[0].next_element.children.map {|e| e.text.squish}.reject{|r| r.empty?}.join("\n")
  end
end
