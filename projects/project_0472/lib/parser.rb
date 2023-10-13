class Parser < Hamster::Parser
  
  def parser(html,run_id)
    body = Nokogiri::HTML(html)
    data_array = []
    body.css("tbody tr").each do |row|
      data_hash = {}
      data_hash[:name] = fetch_values(row, "Full Name")
      data_hash[:registration_status] = fetch_values(row, "Member Type")
      data_hash[:type]                = fetch_values(row, "Member Type")
      date      = fetch_values(row, "Date of Admission")
      data_hash[:date_admited]        = Date.strptime(date, '%m/%d/%Y').to_date rescue nil
      address                         = fetch_values(row, "City, State")
      data_hash[:law_firm_address]    = address
      data_hash[:law_firm_city]       = city_state_selector(address)[0]
      data_hash[:law_firm_state]      = city_state_selector(address)[1]
      data_hash                       = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash]            = create_md5_hash(data_hash)
      data_hash[:first_name], data_hash[:last_name], data_hash[:middle_name] = name_split(data_hash[:name])
      data_hash[:run_id]              = run_id
      data_hash[:touched_run_id]      = run_id
      data_array.append(data_hash)
    end
    data_array
  end

  private

  def name_split(full_name)
    name_spliting = full_name.strip.split(' ')
    middle_name, last_name = nil, nil
    alpha_dot_array = ("A.".."Z.").map(&:to_s)
    alpha_array = ("A".."Z").map(&:to_s)
    first_name  = (alpha_dot_array.include? name_spliting[0]) || (alpha_array.include? name_spliting[0]) ? name_spliting[1] :  name_spliting[0] rescue nil

    if name_spliting.count == 1
      middle_name = nil
      last_name = nil
    elsif name_spliting.count == 2
      middle_name = nil
      last_name = name_spliting[1]
    elsif name_spliting.count == 3
      m_name = name_spliting.select{|a| (alpha_array.include? a.upcase) || (alpha_dot_array.include? a.upcase)}
      middle_name = m_name.empty? ? name_spliting[1] : m_name[0]
      last_name = name_spliting[-1]
    elsif name_spliting.count > 3
      middle_name = name_spliting[1]
      last_name = name_spliting[2..-1].join(" ")
    end
    [first_name, last_name, middle_name]
  end

  def fetch_values(row, key)
    values = row.css("td").select{|e| e.children.css("data-label")}.select{|a| a.values.include? key}
    values.nil? ? nil : values[0].text.squish
  end

  def city_state_selector(address)
    state_county = address.split(",")
    if state_county.count > 1
      city  = state_county[0]
      state = state_county[1]
      [city,state]
    elsif state_county.count == 1
      city,state = (state_county.length < 3) ? [nil, state_county[0]] : [state_county[0], nil]
      [city,state]
    else
      [nil, nil]
    end
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.squish.empty?) ? nil : value.to_s.squish.strip}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
