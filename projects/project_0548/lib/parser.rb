class Parser  
  def initialize
    super
    @scraper = Scraper.new
  end

  def get_case_name(file_content)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    json_object['caseDesc']
  end

  def get_case_number(file_content)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    json_object['caseNumber']
  end

  def page_exist?(file_content)
    doc = Nokogiri::HTML(file_content)
    !doc.at_css('div.alert.alert-danger').present?
  end  

  def get_court_id(case_number)
    court_id =
    if case_number.include?('OSCDB0024_SUP')
      326
    elsif case_number.include?('SMPDB0005_EAP')
      442
    elsif case_number.include?('SMPDB0001_SAP')
      443
    elsif case_number.include?('SMPDB0001_WAP')
      444
    elsif case_number.include?('SC')
      326
    elsif case_number.include?('ED')
      442
    elsif case_number.include?('SD')
      443
    elsif case_number.include?('WD')
      444 
    else
      case_number
    end
  end

  def get_court_name(lowercourt_id,case_number)
    court_name =
    if lowercourt_id.include?('SUP')
      "Supreme Cout OF Missouri"
    elsif lowercourt_id.include?('EAP')
      "Missouri Court of Appeals Eastern District"
    elsif lowercourt_id.include?('SAP')
      "Missouri Court of Appeals Southern District"
    elsif lowercourt_id.include?('WAP')
      "Missouri Court of Appeals Western District"
    elsif case_number[0, 2].include?('SC')
        "Supreme Cout OF Missouri"
    elsif case_number[0, 2].include?('ED')
        "Missouri Court of Appeals Eastern District"
    elsif case_number[0, 2].include?('SD')
        "Missouri Court of Appeals Southern District"
    elsif case_number[0, 2].include?('WD')
        "Missouri Court of Appeals Western District"  
    elsif lowercourt_id != 'NULL'
      get_courtname_link(lowercourt_id,case_number)
    else
      nil  
    end
  end

  def get_courtname_link(lowercourt_id,case_number)
    url = "https://www.courts.mo.gov/cnet/cases/newHeaderData.do?caseNumber=#{case_number}&courtId=#{lowercourt_id}&isTicket=&locnCode="
    url_response, status = @scraper.download_page(url)
    doc = Nokogiri::HTML(url_response.body)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    court_name = json_object['location']
    court_name
  end  
  
  def add_data_soruce_md5(hash)
    hash['deleted'] = 0
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def circourt_present?(file_content)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    json_object['circuitCaseNo'].present? 
  end  

  def appcourt_present?(file_content)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    json_object['appellateCaseNo'].present? 
  end  

  def parse_add_caseinfo(file_content, case_number)
    case_adds = []
    case_numbers = []
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    court_id_url = json_object['courtId']
    court_id = get_court_id(court_id_url)
    disposition = !json_object['caseDispositionDetail'].nil? ? json_object['caseDispositionDetail']['dispositionDescription'] : nil
    if !json_object['appellateCaseNo'].nil?
      lower_case_id = json_object['appellateCaseNo']['caseValue']
      case_macthes = lower_case_id.scan(/\b([A-Z]{2}\d+(?:_[A-Z0-9]+)*)(?=[\s,_]|$|\band\b)/i) 
      if case_macthes.empty?
        case_numbers << lower_case_id
        #lower_court_ids << get_court_id(case_numbers.join(' '))
      else            
        case_macthes.each do |case_match|  
         case_numbers2 = case_match[0].split(/_|\band\b/)
         case_numbers += case_numbers2
        end
      end  
      if json_object['appellateCaseNo']['courtId'].present?
        lower_court_name= get_court_name(json_object['appellateCaseNo']['courtId'],lower_case_id)
      elsif lower_case_id.present?
        lower_court_name = get_court_name('NULL',lower_case_id)
      else
        lower_court_name = nil
      end  
    elsif !json_object['circuitCaseNo'].nil? && !json_object['circuitCaseNo']['caseValue'].nil?
      if json_object['circuitCaseNo']['caseValue'].include?('.')
        lower_case_id = json_object['circuitCaseNo']['caseValue'].split('.').last.strip
        case_numbers << lower_case_id
      else  
        lower_case_id = json_object['circuitCaseNo']['caseValue']
        case_numbers << lower_case_id
      end
      if json_object['circuitCaseNo']['courtId'].present?
        lower_court_name = get_court_name(json_object['circuitCaseNo']['courtId'], lower_case_id)
      elsif lower_case_id.present?
        lower_court_name = get_court_name('NULL',lower_case_id)
      else
         lower_court_name = nil
      end  
    else
      case_numbers << nil
      lower_court_name = nil
    end    
    data_source_url = "https://www.courts.mo.gov/cnet/cases/newHeaderData.do?caseNumber=#{case_number}&courtId=#{court_id_url}&isTicket=&locnCode="
    case_numbers.each do |cases|
      case_adds << {
                  court_id: court_id,
                  case_id: case_number,
                  disposition: disposition,
                  lower_case_id: cases.to_s,
                  lower_court_name: lower_court_name,
                  data_source_url: data_source_url,
                  deleted: 0,
                  md5_hash: Digest::MD5.hexdigest(data_source_url+cases.to_s),
                  lower_judge_name: nil,
                  lower_judgement_date: nil,
                  lower_link: nil
             }
    end 
  case_adds 
  end  

  def parse_case_info(file_content, case_name, case_number)
    case_infos = []
    #lower_court_ids = [] 
    #case_numbers = []
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    court_id_url = json_object['courtId']
    court_id = get_court_id(court_id_url)
    date_field =  json_object['filingDate']
    date = Date.strptime(date_field, '%m/%d/%Y')
    case_type =  json_object['caseType']
    case_description = nil
    disposition_or_status = nil
    if json_object['caseDispositionDetail']['dispositionDescription'].present?
      status_as_of_date = json_object['caseDispositionDetail']['dispositionDescription']
    else
      status_as_of_date = nil
    end
    judge_name = nil
    if !json_object['appellateCaseNo'].nil? 
      lower_case_id = json_object['appellateCaseNo']['caseValue']
      if json_object['appellateCaseNo']['courtId'].present?
          lower_court_id = json_object['appellateCaseNo']['courtId']
          lower_court_id = get_court_id(lower_court_id)        
      elsif lower_case_id.present?
          lower_case_id_value = lower_case_id[0, 2]
          lower_court_id = get_court_id(lower_case_id_value) 
      else  
          lower_court_id = nil
      end    
    elsif !json_object['circuitCaseNo'].nil? && !json_object['circuitCaseNo']['caseValue'].nil?
      if json_object['circuitCaseNo']['caseValue'].include?('.')
        lower_case_id = json_object['circuitCaseNo']['caseValue'].split('.').last.strip
      else  
        lower_case_id = json_object['circuitCaseNo']['caseValue']
      end
      if json_object['circuitCaseNo']['courtId'].present?
        lower_court_id = json_object['circuitCaseNo']['courtId']
      else
        lower_court_id = nil
      end   
    else
      lower_case_id = nil 
      lower_court_id = nil
    end
    data_source_url = "https://www.courts.mo.gov/cnet/cases/newHeaderData.do?caseNumber=#{case_number}&courtId=#{court_id_url}&isTicket=&locnCode="
          case_infos << {
          court_id: court_id,
          case_id: case_number,
          case_name: case_name,
          case_filed_date:  date.strftime('%Y-%m-%d'),
          case_type: case_type,
          case_description: case_description,
          disposition_or_status: disposition_or_status,
          status_as_of_date: status_as_of_date,
          judge_name: judge_name,
          lower_case_id:  lower_case_id,
          lower_court_id: lower_court_id,
          data_source_url: data_source_url,
          deleted: 0,
          md5_hash: Digest::MD5.hexdigest(data_source_url+lower_case_id.to_s) 
          }
    case_infos 
  end
  
  def parse_activity_page(file_content,activity_url,case_number,court_id_url)
    court_id = get_court_id(court_id_url)
    doc = Nokogiri::HTML(file_content)
    @activities = []
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    act_details_list = json_object['docketTabModelList']
    act_details_list.each do |act|
      date_field = act['filingDate']
      date = Date.strptime(date_field, '%m/%d/%Y')
      if !act['associatedDocketInfoDetails'].nil?
        if !act['associatedDocketInfoDetails']['associatedDate'].nil? || act['associatedDocketInfoDetails']['associatedDescription'].nil? || act['associatedDocketInfoDetails']['associatedText'].nil?
          act_desc = act['docketText'].to_s
          act_desc += " " + act['associatedDocketInfoDetails']['associatedDate'].to_s if act['associatedDocketInfoDetails']['associatedDate'].present?
          act_desc += " " + act['associatedDocketInfoDetails']['associatedDescription'].to_s if act['associatedDocketInfoDetails']['associatedDescription'].present?
          act_desc += " " + act['associatedDocketInfoDetails']['associatedText'].to_s if act['associatedDocketInfoDetails']['associatedText'].present?
          if !act['filingPartyFullName'].nil?  || !act['behalfOfPartiesNames'].nil?
            act_desc += "Filed By:" + " " + act['filingPartyFullName'].to_s if act['filingPartyFullName'].present?
            act_desc +=  "  "+"On Behalf Of:" + " " + act['behalfOfPartiesNames'].to_s if act['behalfOfPartiesNames'].present?
          end    
        end             
      else
        act_desc = act['docketText'].to_s
        if !act['filingPartyFullName'].nil?  || !act['behalfOfPartiesNames'].nil?
          act_desc += "  Filed By:" + " " + act['filingPartyFullName'].to_s if act['filingPartyFullName'].present?
          act_desc += "   On Behalf Of:" + " " + act['behalfOfPartiesNames'].to_s if act['behalfOfPartiesNames'].present?
        end  
      end  
      if act_desc == ''
        act_desc = nil
      end  
      activity_type = act['docketDesc'] == '' ? nil : act['docketDesc']
      @activities.push({
        court_id: court_id,
        case_id: case_number,
        activity_date: date.strftime('%Y-%m-%d'),
        activity_type: activity_type,
        activity_desc: act_desc,
        file: nil,
        data_source_url: activity_url
        })
    end
    @activities = @activities.map {|hash| add_data_soruce_md5(hash)}
    @activities 
  end
  
  def parse_party_info(file_content, party_url,c_number,court_id_url)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    party_details_list = json_object['partyDetailsList']
    court_id = get_court_id(court_id_url)
    parties = []
    party_details_list.each do |party|
    party_address = party['formattedPartyAddress'] == '' || party['formattedPartyAddress'] =~ /\A\.{2,5}\z/ ? nil : party['formattedPartyAddress']
    party_description = party['formattedTelePhone'] == '' ? nil : party['formattedTelePhone']   
    party_city = party['addrCity'] =~ /\A\.{2,5}\z/ ? nil : party['addrCity']
    is_lawyer = 0
    parties.push({
        court_id: court_id,
        case_id: c_number,
        party_name: party['formattedPartyName'],
        party_type: party['desc'],
        is_lawyer: is_lawyer,
        party_law_firm: nil,
        party_address: party_address,
        party_city: party_city,
        party_state: party['addrStatCode'],
        party_zip: party['addrZip'],
        party_description: party_description,
        data_source_url: party_url
      })
    attorney_list = party['attorneyList']
      if !attorney_list.empty?
        is_lawyer = 1
        attorney = attorney_list[0]
        party_address = attorney['formattedPartyAddress'] == '' || attorney['formattedPartyAddress'] =~ /\A\.{2,5}\z/ ? nil : attorney['formattedPartyAddress']
        party_description = attorney['formattedTelePhone'] == '' ? nil : attorney['formattedTelePhone']   
        party_city = attorney['addrCity'] =~ /\A\.{2,5}\z/ ? nil : attorney['addrCity']
        parties.push({
          court_id: court_id,
          case_id: c_number,
          party_name: attorney['formattedPartyName'],
          party_type: attorney['desc'],
          is_lawyer:is_lawyer,
          party_law_firm: nil,
          party_address: party_address,
          party_city: party_city,
          party_state: attorney['addrStatCode'],
          party_zip: attorney['addrZip'],
          party_description: party_description,
          data_source_url: party_url
          })
        co_attorney_list = attorney['coAttorneyList']
        unless co_attorney_list.nil?
          co_attorney_list.each do |co_attorney|
            party_address = co_attorney['formattedPartyAddress'] == '' || co_attorney['formattedPartyAddress'] =~ /\A\.{2,5}\z/ ? nil : co_attorney['formattedPartyAddress']
            party_description = co_attorney['formattedTelePhone'] == '' ? nil : co_attorney['formattedTelePhone']   
            party_city = co_attorney['addrCity'] =~ /\A\.{2,5}\z/ ? nil : co_attorney['addrCity']

            parties.push({
              court_id: court_id,
              case_id: c_number,
              party_name: co_attorney['formattedPartyName'],
              party_type: co_attorney['desc'],
              is_lawyer:is_lawyer,
              party_law_firm: nil,
              party_address: party_address,
              party_city: party_city,
              party_state: co_attorney['addrStatCode'],
              party_zip: co_attorney['addrZip'],
              party_description: party_description,
              data_source_url: party_url

              })
          end
        end  
      end
    end
    parties = parties.map {|hash| add_data_soruce_md5(hash)}
    parties
  end  
  
  def parse_opinion_page(file_content, file_name)
    year = file_name.match(/(\d{4})\.html$/)[1]
    doc = Nokogiri::HTML(file_content)
    url = "https://www.courts.mo.gov/page.jsp?id=12086&dist=Opinions&date=all&year=#{year}#all"
    opinion_files = []
    doc.css(".panel-heading.sr-only").each do |date_div|
      date = date_div.text.strip
      date = Date.strptime(date, '%m/%d/%Y')
      date = date.strftime('%Y-%m-%d')
      cases_div = date_div.parent.css(".list-group").css('.list-group-item')
      cases_div.each do |case_div| 
        links = case_div.css('a').select {|a| a['href'] =~ /file\.jsp/ && a.text !~ /Orders/ && a.text !~ /Overview/}
        pdf_link = links.map {|a| a['href']}.flatten
        pdf_link = pdf_link.join(", ")
        source_link = "https://www.courts.mo.gov#{pdf_link}"
        pdf_link_md5_hash = Digest::MD5.hexdigest(source_link)
        if case_div.css('.list-group-item-text b:first-child').text && !case_div.css('.list-group-item-text b:first-child').text.include?('Order')
          case_numbers = []
          case_id = case_div.css('.list-group-item-text b:first-child').text
          case_id = case_id.split(':').first
          case_numbers2 = case_id.scan(/\b([A-Z]{2}\d+(?:_[A-Z0-9]+)*)(?=[\s,]|$)/)
          case_id.scan(/\b([A-Z]{2}\d+(?:_[A-Z0-9]+)*)(?=[\s,_]|$|\band\b)/i) do |matches| 
            case_numbers2 = matches[0].split(/_|\band\b/)
            case_numbers += case_numbers2
          end
          case_numbers.map! { |case_number| case_number.gsub(/consolidated|with|and/, "")}
          if case_numbers.length > 1
            case_numbers.each do |cases|
            court_id = get_court_id(cases.to_s)
            if !(cases == "")
              opinion_files << {
                court_id: court_id,
                case_id: cases,
                case_date: date,
                source_type: 'activity',
                source_link: source_link,
                aws_html_link: nil,
                data_source_url: url,
                deleted: 0,
                md5_hash: pdf_link_md5_hash
              }
            end
            end
          end
        end
        if case_id && !(case_numbers.length > 1)
          court_id = get_court_id(case_numbers.to_s)
          opinion_files << {
            court_id: court_id,
            case_id: case_id,
            case_date: date,
            source_type: 'activity',
            source_link: source_link,
            aws_html_link: nil,
            data_source_url: url,
            deleted: 0,
            md5_hash: pdf_link_md5_hash
          }
        end
      end
    end
    opinion_files
  end
  end