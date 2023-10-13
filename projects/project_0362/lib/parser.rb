require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def attorney_links(page)
    body = Nokogiri::HTML.parse(page.body)
    items = body.css('.attorney-number-link')
    links = []
    items.each do |item|
      text = item.text
      link = item[:href]
      links << {text: text, link: link}
    end
    links.uniq!
    links
  end

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    data_source_url = body.css('.original_link').text
    main = body.css('.original_main .docket-header')
    court = main.css('.docket-header-1')[0].text.to_s.strip
    court_id = court.downcase.include?('supreme') ? 322 : 438
    case_name = main.css('.docket-header-1')[1].text.to_s.strip
    case_id = main.css('.docket-header-2').last.text.to_s.strip
    dockets = body.css('.content-body .docket')
    header_index = nil
    party_index = nil
    entries_index = nil
    documents_index = nil
    header = {}
    activities = []
    files = []
    parties = []
    dockets.each_with_index do |docket, index|
      header_index = index if docket.to_s.include? 'CASE HEADER'
      party_index = index if docket.to_s.include? 'INVOLVED PARTY' or docket.to_s.include? 'ATTORNEY APPEARANCE'
      entries_index = index if docket.to_s.include? 'DOCKET ENTRIES'
      documents_index = index if docket.to_s.include? 'DOCUMENTS'
    end
    unless header_index.blank?
      header_rows = dockets[header_index].css('.col-12 span.ds-bold')
      case_status = nil
      nature = nil
      entry_date = nil
      case_type = nil
      quorum = nil
      single_justice = nil
      panel = nil
      decision_date = nil
      lower_ct_judge = nil
      lower_ct_number = nil
      ac_sj_number = nil
      lower_court = nil
      lower_link = nil
      tc_number = nil
      tc_entry_date = nil
      header_rows.each do |row|
        case_status = row.css('span').text.to_s.strip if row.to_s.include? 'Case Status'
        case_status = nil if case_status.blank?
        nature = row.css('span').text.to_s.strip if row.to_s.include? 'Nature'
        nature = nil if nature.blank?
        entry_date = row.css('span').text.to_s.strip if row.to_s.include? 'Entry Date'
        case_type = row.css('span').text.to_s.strip if row.to_s.include? 'Case Type'
        case_type = nil if case_type.blank?
        quorum = row.css('span').text.to_s.strip if row.to_s.include? 'Quorum'
        quorum = nil if quorum.blank?
        single_justice = row.css('span').text.to_s.strip if row.to_s.include?('Single Justice') && !row.to_s.include?('Route')
        single_justice = nil if single_justice.blank?
        panel = row.css('span').text.to_s.strip if row.to_s.include? 'Panel'
        panel = nil if panel.blank?
        if row.to_s.include? 'AC/SJ Number'
          ac_sj_number = row.css('span').text.to_s.strip
          ac_sj_number = nil if ac_sj_number.blank?
          if ac_sj_number.blank?
            lower_link = nil
          else
            lower_link = row.css('span a')
            lower_link = lower_link.blank? ? nil : lower_link[0]['href'].to_s.strip
          end
        end
        decision_date = row.css('span').text.to_s.strip if row.to_s.include? 'Decision Date'
        tc_entry_date = row.css('span').text.to_s.strip if row.to_s.include? 'TC Entry Date'
        lower_court = row.css('span').text.to_s.strip if row.to_s.include?('Lower Court') && !row.to_s.include?('Judge') && !row.to_s.include?('Number')
        lower_court = nil if lower_court.blank?
        lower_ct_number = row.css('span').text.to_s.strip if row.to_s.include? 'Lower Ct Number'
        lower_ct_number = nil if lower_ct_number.blank?
        tc_number = row.css('span').text.to_s.strip if row.to_s.include? 'TC Number'
        tc_number = nil if tc_number.blank?
        lower_ct_judge = row.css('span').text.to_s.strip if row.to_s.include?('Lower Ct Judge') || row.to_s.include?('Lower Court Judge')
        lower_ct_judge = nil if lower_ct_judge.blank?
      end
      entry_date = entry_date.blank? ? nil : Date.strptime(entry_date, '%m/%d/%Y')
      decision_date = decision_date.blank? ? nil : Date.strptime(decision_date, '%m/%d/%Y')
      tc_entry_date = tc_entry_date.blank? ? nil : Date.strptime(tc_entry_date, '%m/%d/%Y')
      judge_name = quorum
      judge_name = single_justice if judge_name.blank?
      judge_name = panel if judge_name.blank?
      if court_id == 322 && !ac_sj_number.blank?
        header = { case_filed_date: entry_date, lower_judgment_date: decision_date, case_type: case_type, case_description: nature,
                   judge_name: judge_name, status_as_of_date: case_status, lower_court_id: 438, lower_court_name: 'Massachusetts Court of Appeals',
                   lower_case_id: ac_sj_number, lower_link: lower_link, lower_judge_name: nil }
      elsif court_id == 322 && ac_sj_number.blank?
        header = { case_filed_date: entry_date, lower_judgment_date: nil, case_type: case_type, case_description: nature,
                   judge_name: judge_name, status_as_of_date: case_status, lower_court_id: nil, lower_court_name: lower_court,
                   lower_case_id: lower_ct_number, lower_link: nil, lower_judge_name: lower_ct_judge }
      else
        header = { case_filed_date: entry_date, lower_judgment_date: tc_entry_date, case_type: case_type, case_description: nature,
                   judge_name: judge_name, status_as_of_date: case_status, lower_court_id: nil, lower_court_name: lower_court,
                   lower_case_id: tc_number, lower_link: nil, lower_judge_name: lower_ct_judge }
      end
    end
    unless documents_index.blank?
      documents_rows = dockets[documents_index].css('li')
      documents_rows.each do |row|
        link = row.css('a')[0][:href]
        name = row.css('a')[0].text.to_s
        files << { link: link, name: name}
      end
    end
    unless entries_index.blank?
      entries_rows = dockets[entries_index].css('table tr')[1..]
      entries_rows.each do |row|
        activity_date = row.css('td')[0].text.to_s.strip
        activity_date = activity_date.blank? ? nil : Date.strptime(activity_date, '%m/%d/%Y')
        activity_paper = row.css('td')[1].text.to_s.strip
        activity_paper = activity_paper.gsub(/\D/,'').strip unless activity_paper.blank?
        activity_paper = nil if activity_paper.blank?
        activity_desc = row.css('td')[2].text.to_s.strip
        activity_desc = activity_desc.gsub(/\s/,' ').gsub(' ', ' ').squeeze(' ').gsub('View Webcast', '').strip
        activity_desc = nil if activity_desc.blank?
        activity_type = activity_desc[/^[A-Z]{2,}(\s[A-Z]{2,})*/]
        file_link = nil
        unless files.blank?
          unless activity_paper.blank?
            activity_paper = '0' + activity_paper.strip if activity_paper.length == 1
            files_links = []
            files.each do |file|
              link_number = file[:link].gsub(/^.+#{case_id}_/,'').gsub(/_.+/,'')
              files_links << file[:link] if link_number == activity_paper
            end
            file_link = files_links.join(', ').squeeze(' ') unless files_links.blank?
          end
        end
        activities << {
          court_id: court_id,
          case_id: case_id,
          activity_date: activity_date,
          activity_desc: activity_desc,
          activity_type: activity_type,
          file: file_link
        }
      end
    end
    unless party_index.blank?
      party_rows = dockets[party_index].css('.party')
      party_rows.each do |row|
        party = row.css('div')[0].to_s.split('<br>')
        party_name = party.count >= 1 ? Nokogiri::HTML.parse(party[0]).text.to_s.strip : nil
        party_type = party.count >= 2 ? Nokogiri::HTML.parse(party[1]).text.to_s.strip : nil
        parties << {
          court_id: court_id,
          case_id: case_id,
          is_lawyer: 0,
          party_name: party_name,
          party_type: party_type,
          party_law_firm: nil,
          party_address: nil,
          party_city: nil,
          party_state: nil,
          party_zip: nil,
          party_description: nil
        }
        lawyers = row.css('div')[1].css('.flex_span')
        lawyers.each do |item|
          if item.css('a').blank?
            lawyer_party_name_description = item.text.to_s.strip.split(',')
            lawyer_party_law_firm = nil
            lawyer_party_address = nil
            lawyer_party_city = nil
            lawyer_party_state = nil
            lawyer_party_zip = nil
          else
            lawyer_party_name_description = item.css('a').text.to_s.split(',')
            lawyer_party_link = item.css('a')[0]['href']
            lawyer_class = Digest::MD5.hexdigest(lawyer_party_link)
            lawyer_info = body.css(".original_attorneys .hash_" + lawyer_class)[0]
            next if lawyer_info.blank?
            lawyer_info = lawyer_info.css('.original_attorney_body')
            attorney_rows = lawyer_info.css('.attorney_detail .my-3 .row')
            address_text = nil
            lawyer_party_law_firm = nil
            lawyer_party_address = nil
            lawyer_party_city = nil
            lawyer_party_state = nil
            lawyer_party_zip = nil
            attorney_rows.each do |row|
              address_text = row.css('div')[1].to_s.split('<br>') if row.to_s.include? 'Address'
              unless address_text.blank?
                if address_text.count == 5
                  lawyer_party_law_firm = Nokogiri::HTML.parse(address_text[0]).text.to_s.strip
                  lawyer_party_address = Nokogiri::HTML.parse(address_text[1]).text.to_s.strip + ', ' + Nokogiri::HTML.parse(address_text[2]).text.to_s.strip
                  party_city_state_zip = Nokogiri::HTML.parse(address_text[3]).text.to_s.strip
                elsif address_text.count == 4
                  lawyer_party_law_firm = Nokogiri::HTML.parse(address_text[0]).text.to_s.strip
                  lawyer_party_address = Nokogiri::HTML.parse(address_text[1]).text.to_s.strip
                  party_city_state_zip = Nokogiri::HTML.parse(address_text[2]).text.to_s.strip
                else
                  lawyer_party_address = Nokogiri::HTML.parse(address_text[0]).text.to_s.strip
                  party_city_state_zip = Nokogiri::HTML.parse(address_text[1]).text.to_s.strip
                end
                if party_city_state_zip.include? ','
                  lawyer_party_city = party_city_state_zip[0, party_city_state_zip.index(',')]
                  lawyer_party_state = party_city_state_zip[party_city_state_zip.index(',') + 1, party_city_state_zip.length].gsub(/\d/, '').strip
                  lawyer_party_zip = party_city_state_zip[party_city_state_zip.length - 5, party_city_state_zip.length].strip
                end
              end
            end
          end
          lawyer_party_type = party_type.blank? ? nil : party_type.strip + ' Lawyer'
          lawyer_party_name = lawyer_party_name_description.count >= 1 ? lawyer_party_name_description[0].strip : nil
          lawyer_party_description = lawyer_party_name_description.count >= 2 ? lawyer_party_name_description[1].strip : nil
          parties << {
            court_id: court_id,
            case_id: case_id,
            is_lawyer: 1,
            party_name: lawyer_party_name,
            party_type: lawyer_party_type,
            party_law_firm: lawyer_party_law_firm,
            party_address: lawyer_party_address,
            party_city: lawyer_party_city,
            party_state: lawyer_party_state,
            party_zip: lawyer_party_zip,
            party_description: lawyer_party_description
          }
        end
      end
    end
    info = {
      court_id: court_id,
      case_id: case_id,
      case_name: case_name,
      case_filed_date: header[:case_filed_date],
      case_type: header[:case_type],
      case_description: header[:case_description],
      status_as_of_date: header[:status_as_of_date],
      judge_name: header[:judge_name],
      lower_court_id: header[:lower_court_id],
      lower_case_id: header[:lower_case_id],
      data_source_url: data_source_url
    }
    add_info = []
    unless header[:lower_case_id].blank?
      lower_case_ids = header[:lower_case_id].split(/;|&|,/)
      lower_case_ids.each do |item|
        next if item.blank?
        add_info << {
          court_id: court_id,
          case_id: case_id,
          lower_court_name: header[:lower_court_name],
          lower_case_id: item.strip,
          lower_judge_name: header[:lower_judge_name],
          lower_link: header[:lower_link],
          disposition: nil,
          data_source_url: data_source_url
        }
      end
    end
    [info, add_info, activities, parties, files]
  end
end
