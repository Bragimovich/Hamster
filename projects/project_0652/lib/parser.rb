# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def page(page)
    @doc = Nokogiri::HTML(page)

    self
  end

  def search_page_uri
    button = @doc.css('a.ssSearchHyperlink[text()="All Case Records Search"]').first
    location = @doc.css('#sbxControlID2 option[text()="Pinellas County"]').first
    location_text = location.text
    location_value = location.attr('value')
    "Search.aspx?ID=300?NodeID=#{location_value}&NodeDesc=#{location_text}"
  end

  def cases
    list = []
    @doc.css('a[href*=CaseDetail]').each do |a|
      list.push(a.attr('href'))
    end

    list
  end

  def case_detail
    data_hash = 
    {
      case_id: case_id,
      case_name: case_name,
      case_type: case_type,
      case_filed_date: case_filed_date,
      judge_name: judge_name
    }
    data_hash[:md5_hash] = create_md5_hash(data_hash.except(:case_name))

    data_hash
  end

  def case_id
    @doc.css('[class=ssCaseDetailCaseNbr] span').first&.text
  end

  def case_name
    @doc.css('#COtherEventsAndHearings , b').first&.text&.gsub(/\n/,' ')
  end

  def case_type
    @doc.css('[text()="Case Type:"]').first&.next_element&.text&.strip
  end

  def case_filed_date
    text = @doc.css('[text()="Date Filed:"]').first&.next_element&.text&.strip
    date_format(text)
  end

  def judge_name
    name = @doc.css('th[text()="Judicial Officer:"]').first&.next_element&.text&.strip
     if name && name.match?(/NO JUDGE/i)
      nil 
     end

     name
  end

  def parties
    list = []
    container = rows = @doc.at_css('[text()*="Party Information"]').parent.parent
    attorney_id = container.at_css('[text()="Attorneys"]').attr("id")
    # pp attorney_id
    container.css("tr").each do |tr|
      next if tr.css('th[class=ssTableHeader]').text.empty?
      party_ids = []
      party_type = tr.at_css('th[class=ssTableHeader][id]:nth-child(1)')
      party_name = tr.at_css('th[class=ssTableHeader][id]:nth-child(2)')
      next if party_type.nil? || party_name.nil?
      next if party_name.text.match?(/IN RE/i)
      data_hash = {
        party_name: party_name.text.strip,
        party_type: party_type.text.strip,
        is_lawyer: 0
      }
      dob_info = nil
      party_description = container.at_css("td[headers*='#{party_type.attr('id')}'][headers*='#{party_name.attr('id')}']:not([headers*='#{attorney_id}']):not(:empty)")
      if party_description.text.match?(/Unavailable|/) || party_description.text.inlclude?('DOB:')
        dob_info = party_description
        party_description= container.css("td[headers*='#{party_type.attr('id')}'][headers*='#{party_name.attr('id')}']:not([headers*='#{attorney_id}']):not(:empty)").last
      end
      raw_address = party_description.inner_html
      address = party_address(raw_address&.split('<br>').reject{|t| t.strip.empty? || t.match?('<nobr>') })
      data_hash[:party_description] = party_description.text.strip
      data_hash[:party_description] += " #{dob_info.text.strip}" unless dob_info.nil?
      unless address.nil?
        data_hash.merge!(**address)
      end
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      list.push(remove_unwanted_chars(data_hash))

      attorneys_container = container.at_css("td[headers*='#{party_type.attr('id')}'][headers*='#{party_name.attr('id')}'][headers*='#{attorney_id}']:not(:empty)")
      # pp attorneys_container
      data_hash = {
        party_type: party_type.text.strip,
        is_lawyer: 1
      }
      nodes = attorneys_container.children
      phone=""
      nodes.each_with_index do |el, index|

        if el.name == 'b'
          data_hash[:party_name] = el.text.strip
        end
        if el.name == 'text' && !el.text.gsub(/[[:space:]]/, '').empty?
          if el.next_element&.name == "br"
            data_hash[:party_name] = el.text.strip 
          else
            phone = el.text.strip.to_s
          end
        end

        if el.name == 'table' 
          if el.attr('style').nil? || el.attr('style').empty?
            data_hash[:md5_hash] = create_md5_hash(data_hash)
            data_hash[:party_description] = [data_hash[:party_description],phone].join(' ') unless (phone.nil? || phone.empty?)
            list.push(remove_unwanted_chars(data_hash)) unless data_hash[:party_name].nil?
            
            data_hash = {
              party_type: party_type.text.strip,
              is_lawyer: 1
            }
          else
            raw_address = el.at_css('td:not(:empty)')&.inner_html.to_s
            address = party_address(raw_address.split('<br>')[1..-1])
            law_firm = raw_address.split('<br>')&.first&.strip&.gsub("<s>", "")
            data_hash[:law_firm] = law_firm&.gsub('&amp;','&')
            unless address.nil?
              data_hash.merge!(**address)
              data_hash[:party_description] = "#{el.at_css('td:not(:empty)').text.strip}"
            end
          end
        end
        
        if index == nodes.size - 1
          data_hash[:md5_hash] = create_md5_hash(data_hash)
          data_hash[:party_description] = [data_hash[:party_description],phone].join(' ') unless (phone.nil? || phone.empty?)
          list.push(remove_unwanted_chars(data_hash)) unless data_hash[:party_name].nil?
          data_hash = {
            party_type: party_type.text.strip,
            is_lawyer: 1
          }
        end
        
      end
    end

    list.uniq
  end

  def date_format(text)
    return unless text
    existing_format = '%m/%d/%Y' 
    existing_format = '%m/%d/%y' if text.length < 10
    date =  Date.strptime(text, existing_format) rescue nil
    
    date = date.strftime('%Y-%m-%d').to_s if date
  end

  def activities
    list = []
    # selected 
    @doc.at_css('th[text()="Selected Event"]')&.parent&.parent&.css('tr')&.map do|tr|
      detail = activity_detail(tr)
      list.push(remove_unwanted_chars(detail)) unless detail.nil?
    end

    # other events
    @doc.at_css('th[text()="Other Events on This Case"]')&.parent&.parent&.css('tr')&.map do|tr|
      detail = activity_detail(tr)
      list.push(remove_unwanted_chars(detail)) unless detail.nil?
    end
    
    list
  end

  def activity_detail(tr)
    data_hash = nil
    date_and_name = tr.at_css('td:nth-child(1)').text.strip rescue nil
    activity_pdf = tr.at_css('td:nth-child(2) a').attr("href") rescue nil
    activity_type =  date_and_name[11..].split('-').first.strip rescue nil
    unless activity_pdf.nil?
      data_hash = {
        activity_date: date_format(date_and_name[0, 10]),
        activity_type: activity_type,
        activity_decs: date_and_name[11..],
        activity_pdf: activity_pdf
      } 
      data_hash[:md5_hash] = create_md5_hash(data_hash)
    end
   
    data_hash
  end

  def activity_link
    @doc.at_css('[class="ssEventsAndOrdersSubTitle"]')&.parent&.parent&.at_css('tr td[headers*="COtherEventsAndHearings"] b a[href]')&.attr("href")
  end

  def case_links
    list = []
    @doc.css('a[href*=CaseDetail]').each do |a|
      list.push(a.attribute('href'))
    end
    list 
  end

  def party_address(address)
    return if address.nil? || address.empty?
    party_address = address.join(' ')
    party_city = address.last.split(',')&.first&.strip
    party_state, party_zip = address.last.split(',').last.split(' ')

    parse_address = {
      party_address: party_address.gsub("</s>", "")&.strip,
      party_city: party_city,
      party_state: party_state&.gsub("</s>", ""),
      party_zip: party_zip&.gsub("</s>", "")
    }
    
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def view_state_params(html)
    page = Nokogiri::HTML(html)
    viewstate = page.at_css("#__VIEWSTATE")&.attr('value')
    viewstategenerator = page.at_css("#__VIEWSTATEGENERATOR")&.attr('value')
    eventvalidation = page.at_css("#__EVENTVALIDATION")&.attr('value')
    [viewstate, viewstategenerator, eventvalidation]
  end
  
  def valid_search_page?
    if @doc.at_css('a[href*=CaseDetail]')
      true
    end
  end

  def remove_unwanted_chars(hash)
    # replace empty values with nil
    hash.each do |k, v|
       if v.kind_of?(String)
        hash[k] = nil if v.empty?
        unless hash[k].nil?
          hash[k] = v.gsub(/nbsp;/i,' ')
          .gsub(/&amp;/i,'&')
          .gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
          .strip
        end
       end
    end

    hash
  end

  def record_count
    @doc.at_css('b:contains("Record Count:")').parent.parent.children.last.text.strip.to_i rescue nil
  end

  def search_success?
    @doc.css('b:contains("Record Count:")').count > 0
  end

end
