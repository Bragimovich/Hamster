class Parser
  BASE_URL = "https://www.mywsba.org/PersonifyEbusiness/LegalDirectory/LegalProfile.aspx"

  def get_results_count(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    parsed_page.css('.results-count')[0].content.split(' ')[0].to_i
  end

  def get_all_user_ids(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    html_list_lawyers = parsed_page.css('.search-results').css('.grid-row')
    user_ids = []
    cities = []
    html_list_lawyers.each do |lawyer_on_page|
      user_id = lawyer_on_page['onclick'].split('?Usr_ID=')[-1][0..-2]
      cities << lawyer_on_page.elements[3]&.content
      user_ids << user_id
    end
    [user_ids, cities]
  end

  def parse_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    lawyers = []
    html_list_lawyers = parsed_page.css('.search-results').css('.grid-row')

    html_list_lawyers.each do |lawyer_on_page|
      columns = lawyer_on_page.css('td')
      first_name = columns[1].content.strip
      first_name,middle_name = first_name.split(' ')
      user_id = lawyer_on_page['onclick'].split('?Usr_ID=')[-1][0..-2]
      href = BASE_URL + "?Usr_ID=#{user_id}"
      
      hash = {
        bar_number: columns[0].content.strip,
        first_name: first_name,
        middle_name: middle_name,
        last_name: columns[2].content.strip,
        law_firm_city: columns[3].content.strip,
        registration_status: columns[4].content.strip,
        phone: columns[5].content.strip,
        link: href
      }
      lawyers << hash
    end
    lawyers
  end



  def parse_lawyer(file_content)
    doc = Nokogiri::HTML(file_content)
  
    lawyer = {}
    body = doc.css('.LegalProfileControl_PersonifyDefault')[0]
    
    hash_name = { 
      "License Type:"=> :type, 
      "WSBA Admit Date:"=> :date_admitted,
      "Practice Areas:"=> :sections,
      "Email:" => :email,
      "Firm or Employer:" => :law_firm_name,
      "Phone:" => :phone, 
      "License Status:"=> :registration_status,
      "License Number:" => :bar_number,
      "Eligible To Practice:" => :eligibility,
      "Website:"=> :law_firm_website,
      "Office Type and Size:" => :office_type,
      "Private Practice:" => :private_practice,
    }
    
    lawyer = {
      :name => nil,
      :type=>nil,
      :date_admitted=>nil, 
      :law_firm_name=>nil, 
      :law_firm_address=>nil,
      :law_firm_state=>nil,
      :law_firm_zip=>nil,
      :email=>nil,
      :sections=>nil,
      :phone=>nil,
      :registration_status=>nil,
      :bar_number=>nil,
      :eligibility=>nil,
      :law_firm_website=>nil,
      :office_type=>nil,
      :private_practice=>nil,
    }
    
    body.css('tr').each do |row|
      row_name = row.css('td strong')[0]
      next if row_name.nil?
      row_name = row_name.content
      if row_name.include?("WSBA Admit Date")
        lawyer[hash_name[hash_name.keys[1]]] = row.css('td')[1].content&.strip
      end

      if row_name.in?(hash_name.keys)
        lawyer[hash_name[row_name]] = row.css('td')[1].content&.strip
      end
    end
  
    law_firm_address = body.css('#dnn_ctr2977_DNNWebControlContainer_ctl00_lblAddress')[0]
    unless law_firm_address.nil?
      law_firm_address.css('br').each { |br| br.replace("\n") }
      lawyer[:law_firm_address] = law_firm_address.content.strip.split("\n")[0...-1].join("\n").strip
      state_zip = lawyer[:law_firm_address].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
      lawyer[:law_firm_state], lawyer[:law_firm_zip] = state_zip.strip.split(' ') if !state_zip.nil?
      lawyer[:law_firm_address] = lawyer[:law_firm_address]&.sub("\n",' ')
      lawyer[:law_firm_state] = lawyer[:law_firm_state]&.sub("\n",' ')
      lawyer[:law_firm_zip] = lawyer[:law_firm_zip]&.sub("\n",' ')
    end
  
    lawyer.each_pair do |key, value|
      lawyer[key] = nil if value=='' or value == "None Specified"
    end

    unless lawyer[:phone].nil?
      if lawyer[:phone].match(/\((000)\)/)
        lawyer[:phone] = nil
      end
    end
  
    unless lawyer[:date_admitted].nil?
      lawyer[:date_admitted] = Date.strptime(lawyer[:date_admitted], '%m/%d/%Y').to_date.to_s
    end
    lawyer_full_name = doc.css('#dnn_ctr2977_DNNWebControlContainer_ctl00_lblMemberName')&.first&.content
    lawyer[:name] = lawyer_full_name&.strip
    first_name, middle_name, last_name =  split_name(lawyer_full_name)
    lawyer[:first_name] = first_name
    lawyer[:last_name] = last_name
    lawyer[:middle_name] = middle_name
    lawyer
  end

  def split_name(full_name)
    name_parts = full_name.split(' ')
    if name_parts.length > 2
      middle_name = name_parts[1]
      first_name = name_parts[0]
      last_name = name_parts[-1]
    else
      middle_name = ''
      first_name = name_parts[0]
      last_name = name_parts[-1]
    end
    [first_name, middle_name, last_name]
  end
  
end