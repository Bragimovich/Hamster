# frozen_string_literal: true

class ParserFLSAAC < Hamster::Scraper

  def initialize(**options)
    super
    #@run_id = options[:run_id]
  end

  def parties(general_page, court:1, party_type:'Party')
    parties = []
    doc = Nokogiri::HTML(general_page)
    if court=='sa'
      unless doc.css('table.table-striped')[1].nil?
        doc.css('table.table-striped')[1].css('tr')[1..].each do |tr|
          tds = tr.css('td')
          party_link = tds[6].css('a').first
          person_id = party_link['href'].match(/PersonId=(?<party_id>.*?)&/)
          party_id = person_id[:party_id] if !person_id.nil?
          parties << {
            party_last_name: tds[0].content.strip,
            party_first_name: tds[1].content.strip,
            party_middle_name: tds[2].content.strip,
            party_type: party_type,
            party_link: "http://onlinedocketssc.flcourts.org" + party_link['href'],
            party_address: tds[4].content.strip,
            party_phone: tds[5].content.strip,
            party_id: party_id,

            case_counter: party_link.content,
            court_id: 310,
          }
        end
      end
    else
      unless doc.css('table.table-striped').first.nil?
        doc.css('table.table-striped').css('tr')[1..].each do |tr|
          tds = tr.css('td')
          party_link = tds.css('a').first
          person_id = party_link['href'].match(/PersonId=(?<party_id>.*?)&/)
          party_id = person_id[:party_id] if !person_id.nil?
          parties << {
            party_last_name: tds[0].content.strip,
            party_first_name: tds[1].content.strip,
            party_middle_name: tds[2].content.strip,
            party_type: party_type.strip,
            party_link: "http://onlinedocketsdca.flcourts.org" + party_link['href'],
            party_address: nil,
            party_phone: nil,
            party_id: party_id,

            case_counter: party_link.content,
            court_id: 414 + court.to_i,
          }
        end
      end
    end
    parties
  end

  def party_cases(party_page, court_id)
    cases = []
    doc = Nokogiri::HTML(party_page)
    if court_id.to_i < 400
      doc.css('table.table-striped')[1].css('tr')[1..].each do |tr|
        tds = tr.css('td')
        case_party = {
          case_id: tds[0].content.strip,
          court_id: court_id,
          status_as_of_date: tds[1].content.strip,
          case_filed_date: Date.strptime(tds[2].content.strip, '%m/%d/%Y'),
          case_type: tds[3].content.strip,
          case_name: tds[4].content.strip,
          case_description: tds[5].content.strip + "\n Disposed: " + tds[6].content.strip,
          data_source_url: "http://onlinedocketssc.flcourts.org" + tds[0].css('a').first['href'],
        }
        next if case_party[:case_filed_date] < Date.parse('2016-01-01')
        cases << case_party
      end
    else
      doc.css('table.table-striped').css('tr')[1..].each do |tr|
        tds = tr.css('td')
        disposed = tds[5].content.strip
        case_description = "Disposed: " + tds[5].content.strip if disposed != ''
        case_party = {
          case_id: "#{(court_id-414)}D" + tds[0].content.strip,
          court_id: court_id,
          status_as_of_date: nil,
          case_filed_date: Date.strptime(tds[1].content.strip, '%m/%d/%Y'),
          case_type: nil,
          case_name: tds[2].content.strip,
          lower_case_id: tds[4].content.strip,
          case_description: case_description,
          data_source_url: "http://onlinedocketsdca.flcourts.org" + tds[0].css('a').first['href'],
        }
        next if case_party[:case_filed_date] < Date.parse('2016-01-01')
        cases << case_party
      end
    end
    cases
  end

  def case_page(html, case_record)
    doc = Nokogiri::HTML(html)
    return {} unless doc.css('table#tblNoResults').first.nil?
    if case_record[:court_id].to_i < 400
      case_full_info = case_sc(doc, case_record)
      case_additional_info = case_additional_sc(doc, case_full_info)
      activities = activities_sc(doc, case_full_info)
    else
      case_full_info = case_ca(doc, case_record)
      case_additional_info = case_additional_ca(doc, case_full_info)
      activities = activities_ca(doc, case_full_info)
    end

    full_case = {
      info: case_full_info,
      additional_info: case_additional_info,
      activities: activities,
    }
    full_case
  end

  def case_ca(doc, case_record)
    body = doc.css("table#tblCriteria")
    full_case = case_record
    info_rows = body.css('td.modal-title')

    full_case[:case_id] = info_rows[0].content.split("Case Number:")[-1].strip if full_case[:case_id].nil?
    full_case[:case_name] = info_rows[2].content.strip                         if full_case[:case_name].nil?
    full_case[:case_type] = info_rows[1].content.split('from')[0].strip        if full_case[:case_type].nil?
    if full_case[:status_as_of_date].nil? && !full_case[:case_description].nil?
      full_case[:status_as_of_date] = 'Disposed'
    else
      full_case[:status_as_of_date] = 'Active'
    end

    unless info_rows[3].nil?
      lower_case_id = info_rows[3].content.split(':')[-1]
      lower_case_id = lower_case_id[0..500].split(',')[0...-1].join(',') if lower_case_id.length > 500
      full_case[:lower_case_id] = lower_case_id.strip
    else
      full_case[:lower_case_id] = nil
    end

    full_case
  end

  def case_sc(doc, case_record)
    body = doc.css("table#tblCriteria")
    full_case = case_record
    info_rows = body.css('td.modal-title')

    full_case[:status_as_of_date] = info_rows[1].content.split(' - ')[-1].strip if full_case[:status_as_of_date].nil?
    full_case[:case_name] = info_rows[2].content.strip                          if full_case[:case_name].nil?

    unless info_rows[3].nil?
      lower_case_id = info_rows[3].content.split(':')[-1]
      lower_case_id = lower_case_id[0..500].split(',')[0...-1].join(',') if lower_case_id.length > 500
      full_case[:lower_case_id] = lower_case_id.strip
    else
      full_case[:lower_case_id] = nil
    end

    full_case
  end


  def case_additional_ca(doc, case_info)
    additional_info = []
    info_rows = doc.css("table#tblCriteria").css('td.modal-title')
    lower_court_name = info_rows[1].content.split('from')[1]
    lower_court_name = lower_court_name.strip if lower_court_name

    lower_case_ids =
      unless info_rows[3].nil?
        info_rows[3].content.split(':')[-1].strip
      else
        '_'
      end

    lower_case_ids.split(',').each do |lower_case_id|
      lower_case_id == '_' ? lower_case_id = nil : lower_case_id = lower_case_id.strip
      additional_info << {
        lower_case_id: lower_case_id,
        lower_court_name: lower_court_name,
        court_id: case_info[:court_id],
        case_id: case_info[:case_id],
        data_source_url: case_info[:data_source_url],
      }
    end
    additional_info
  end

  def case_additional_sc(doc, case_info)
    additional_info = []
    info_rows = doc.css("table#tblCriteria").css('td.modal-title')
    lower_court_name = info_rows[1].content.split('from')[1]
    lower_court_name = lower_court_name.strip if lower_court_name

    lower_case_ids =
      unless info_rows[3].nil?
        info_rows[3].content.split(':')[-1].strip
      else
        '_'
      end

    lower_case_ids.split(',').each do |lower_case_id|
      lower_case_id == '_' ? lower_case_id = nil : lower_case_id = lower_case_id.strip
      additional_info << {
        lower_case_id: lower_case_id,
        lower_court_name: lower_court_name,
        court_id: case_info[:court_id],
        case_id: case_info[:case_id],
        data_source_url: case_info[:data_source_url],
      }
    end
    additional_info
  end

  def activities_ca(doc, case_info)
    activities = []
    doc.css('table.table-striped').css('tr')[1..].map do |tr|
      tds = tr.css('td')
      activities <<{
        activity_date: Date.strptime(tds[0].content.strip, '%m/%d/%Y'),
        activity_type: tds[1].content.strip,
        activity_desc: tds[1].content.strip+ "\nFiled by:" + tds[2].content.strip + "\nNotes:" + tds[3].content.strip,

        court_id: case_info[:court_id],
        case_id: case_info[:case_id],
        data_source_url: case_info[:data_source_url],
      }
    end
    activities
  end

  def activities_sc(doc, case_info)
    activities = []
    doc.css('table.table-striped')[1].css('tr')[1..].map do |tr|
      tds = tr.css('td')
      activity_pdf = tds[0].css('a')[0]
      activity_pdf = activity_pdf['href'] unless activity_pdf.nil?
      activities <<{
        activity_date: Date.strptime(tds[1].content.strip, '%m/%d/%Y'),
        activity_type: tds[2].content.split('-')[0].strip,
        activity_desc: tds[2].content.strip+ "\nFiled by:" + tds[3].content.strip + "\nNotes:" + tds[4].content.strip,
        activity_pdf: activity_pdf,

        court_id: case_info[:court_id],
        case_id: case_info[:case_id],
        data_source_url: case_info[:data_source_url],
      }
    end
    activities
  end


  def cases_date_filed(html_page, court_id)
    cases = []
    doc = Nokogiri::HTML(html_page)
    if court_id.to_i < 400
      table_striped = doc.css('table.table-striped')[1]
      unless table_striped.nil?
        table_striped.css('tr')[1..].each do |tr|
          tds = tr.css('td')
          case_record = {
            case_id: tds[0].content.strip,
            case_name: tds[1].content.strip,
            court_id: court_id,
            data_source_url: "http://onlinedocketssc.flcourts.org" + tds[0].css('a').first['href'],
          }
          cases << case_record
        end
      end
    else
      table_striped = doc.css('table.table-striped')
      unless table_striped.first.nil?
        table_striped.css('tr')[1..].each do |tr|
          tds = tr.css('td')
          case_record = {
            case_id: tds[0].content.strip,
            court_id: court_id,
            lower_case_id: tds[6].content.strip,
            data_source_url: "http://onlinedocketsdca.flcourts.org" + tds[0].css('a').first['href'],
          }
          cases << case_record
        end
      end
    end
    cases
  end

  def info_to_party(case_id, party)
    party_description = "party_id: #{party[:party_id]}"
    party_description += "\nPhone: #{party[:party_phone]}" unless party[:party_phone].nil?
    case_party = {
      court_id: party[:court_id],
      case_id: case_id,

      party_name: party[:party_last_name]+' '+party[:party_first_name]+' '+party[:party_middle_name],
      party_type: party[:party_type],
      party_address: party[:party_address],
      party_description: party_description,

    }
    case_party[:is_lawyer] = true if case_party[:party_type]=='Attorney'
    case_party
  end

end
