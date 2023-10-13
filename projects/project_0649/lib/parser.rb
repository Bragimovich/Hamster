class Parser < Hamster::Parser

  def get_links(html)
    page = Nokogiri::HTML(html)
    page.css('table tbody tr').map { |e| 'https://propublic.buckscountyonline.org' + e.css('a')[0]['href'] }
  end

  def fetch_info(data_file, file, run_id)
    data = JSON.parse(data_file) rescue nil
    return [] if data.nil?

    url = "https://propublic.buckscountyonline.org/PSI/v/detail/Case/#{file.gsub('.gz', '')}"
    @info_hash = get_info(data, url, run_id)
    return [] if @info_hash.empty?

    party_array = get_parties_data(data, run_id)
    activities_array = get_activities(data, run_id)
    judgment_array = get_judgment(data, run_id)
    [@info_hash, party_array, activities_array, judgment_array]
  end

  private

  def get_judgment(data, run_id)
    data_hash_array = []
    judgments = data['Relates'].select { |e| e.include? 'table_Judgments' }[0]
    return [] if judgments.nil?

    judgments = Nokogiri::HTML(judgments.force_encoding("utf-8"))
    headers = judgments.css('table thead th').map { |e| e.text.squish }
    judgments_data = judgments.css('table tbody tr')
    judgments_data.each do |data|
      data_hash = common_data_hash
      judgment_date = search_party_data(data, headers, 'Date').text rescue nil
      data_hash[:judgment_date] = get_date(judgment_date)
      data_hash[:party_name] = search_party_data(data, headers, 'For').text
      data_hash[:judgment_amount] = search_party_data(data, headers, 'Amount').text rescue nil
      next if data_hash[:judgment_amount].nil?
      data_hash = complete_data_hash(data_hash, run_id)
      data_hash_array << data_hash
    end
    data_hash_array.uniq
  end

  def get_activities(data, run_id)
    data_hash_array = []
    activities = data['Relates'].select { |e| e.include? 'table_DocketEntries' }[0] rescue nil
    return [] if activities.nil?

    activities = Nokogiri::HTML(activities.force_encoding("utf-8"))
    headers = activities.css('table thead th').map { |e| e.text.squish }
    activities_data = activities.css('table tbody tr')
    activities_data.each do |data|
      data_hash = common_data_hash
      activity_date = search_party_data(data, headers, 'Filing Date').text
      data_hash[:activity_date] = get_date(activity_date)
      data_hash[:activity_decs] = search_party_data(data, headers, 'Docket Text').text
      data_hash = complete_data_hash(data_hash, run_id)
      data_hash_array << data_hash
    end
    data_hash_array
  end

  def get_parties_data(data, run_id)
    party_hash_array = []
    parties = data['Relates']
    parties.each do |party|
      check_array = ['table_DocketEntries', 'table_Judgments', 'table_LinkedCases', 'table_ParcelNumbers', 'table_EscrowAccounts', 'table_Microfilms']
      next if check_array.any? { |c| party.include? c }

      detail = Nokogiri::HTML(party.squish.force_encoding("utf-8")) rescue nil
      next if detail.nil?

      type = detail.css('h4').text.squish
      headers = detail.css('table thead th').map { |e| e.text.squish }
      parties_data = detail.css('table tbody tr')
      parties_data.each do |party_data|
        party_hash_array = party_hash_array + get_party(party_data, type, headers, run_id)
      end
    end
    party_hash_array.uniq
  end

  def get_party(party_data, type, headers, run_id)
    name = search_party_data(party_data, headers, 'Name').text
    return [] if name.nil? or name.empty?

    address = search_party_data(party_data, headers, 'Address')
    address_details = find_address(address)
    lawyer_name = search_party_data(party_data, headers, 'Counsel').text
    hash_array = []
    hash_array << get_party_hash(run_id, name, type, 0, address_details)
    hash_array << get_party_hash(run_id, lawyer_name, type, 1) unless lawyer_name.nil? or lawyer_name.empty?
    hash_array
  end

  def get_party_hash(run_id, name, party_type, is_lawyer, address_details = [])
    data_hash = common_data_hash
    data_hash[:party_name] = name.squish
    data_hash[:party_type] = is_lawyer == 1 ?  party_type + ' Attorney' : party_type
    data_hash[:is_lawyer] = is_lawyer
    data_hash[:party_address] = address_details[0]
    data_hash[:party_city] = address_details[1]
    data_hash[:party_state] = address_details[2]
    zip = address_details[3]
    data_hash[:party_zip] = (!zip.nil? and zip.count("a-zA-Z") > 0 ) ? nil : zip
    data_hash = complete_data_hash(data_hash, run_id)
    data_hash
  end

  def find_address(address)
    address = address.children.map { |e| e.text }.reject { |e| e.empty? }
    return [] if address[0] == 'NONE' or address[0] == 'Confidential'

    data = address.last.split(',') rescue nil
    return [] if address.nil?

    city = data.first rescue nil
    zip = data[1].split[1] rescue nil
    state = data[1].split[0] rescue nil
    city = state = zip = nil unless state.nil? or state.length == 2
    address = address.join("\n")
    [address, city, state, zip]
  end

  def search_party_data(party, headers, key)
    index = headers.find_index(headers.select { |e| e == key }[0])
    party.css('td')[index]
  end

  def common_data_hash
    hash = {}
    hash[:court_id] =  @info_hash[0][:court_id]
    hash[:case_id] = @info_hash[0][:case_id]
    hash[:data_source_url] = @info_hash[0][:data_source_url]
    hash
  end

  def complete_data_hash(data_hash, run_id)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def get_info(data, url, run_id)
    info_array = []
    info_hash = {}
    info_hash[:court_id] = 101
    detail = data['Detail'].squish.gsub("\u0000", '') rescue nil
    return [] if detail.nil?

    detail = Nokogiri::HTML5(detail)
    info_data = detail.css('table.ViewerDetail tr')
    caption_plaintiff = search_data(info_data, 'Caption Plaintiff')
    caption_defendant = search_data(info_data, 'Caption Defendant')
    case_name = caption_defendant.empty? ? caption_plaintiff : caption_plaintiff + ' vs ' + caption_defendant
    info_hash[:case_name] = case_name
    case_id = search_data(info_data, 'Case Number')
    matter_code = search_data(info_data, 'Matter Code')
    info_hash[:case_id] = (matter_code.nil? or matter_code.empty?) ? case_id : "#{case_id}-#{matter_code}"
    commencement_date = search_data(info_data, 'Commencement Date')
    info_hash[:case_filed_date] = get_date(commencement_date)
    info_hash[:case_type] = search_data(info_data, 'Case Type')
    info_hash[:case_description] = search_data(info_data, 'Remarks')
    info_hash[:status_as_of_date] = search_data(info_data, 'Status')
    info_hash[:judge_name] = search_data(info_data, 'Judge')
    info_hash[:data_source_url] = url
    info_hash = complete_data_hash(info_hash, run_id)
    info_array << info_hash
    info_array
  end

  def get_date(date)
    Date.strptime(date.split(' ')[0], '%m/%d/%Y') rescue nil
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
 
  def search_data(data, key)
    data.css('th').select { |e| e.text == key }[0].next_element.text rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{ |value| (value.to_s.empty? || value == 'null') ? nil : value }
  end
end
