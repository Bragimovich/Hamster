require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def items(hamster)
    items = Nokogiri::HTML.parse(hamster.body).css('tr')
    case_ids = []
    items.each do |item|
      unless item.css('td a').blank?
        case_id = item.css('td')[0].css('a').text.to_s.strip
        case_status = item.css('td')[2].text.to_s.strip
        case_ids << {'case_id': case_id, 'case_status': case_status}
      end
    end
    case_ids
  end

  def parties(hamster)
    page_parties = Nokogiri::HTML.parse(hamster.body).css('table')[1]
    parties = page_parties.css('tr')[1..]
    parties_info = []
    parties.each do |party|
      party_name = party.css('td')[0].text.to_s.strip
      party_type = party.css('td')[1].text.to_s.strip
      party_link = 'https://www.iowacourts.state.ia.us' + party.css('td')[0].css('a')[0]['href']
      parties_info << { 'party_name': party_name, 'party_type': party_type,'party_link': party_link }
    end
    parties_info
  end

  def info_parse(page)
    body = Nokogiri::HTML.parse(page)
    case_id = body.css('.original_case_id').text
    case_name = case_name(body.css('.original_summary'))
    case_filed_date = case_filed_date(body.css('.original_docket'))
    case_type = case_type(body.css('.original_summary'))
    case_description = case_description(body.css('.original_long'))
    case_status = body.css('.original_case_status').text
    judge_name = case_judge(body.css('.original_summary'))
    data_source_url = body.css('.original_link_summary').text
    info = {
      court_id: 429,
      case_id: case_id,
      case_name: case_name,
      case_filed_date: case_filed_date,
      case_type: case_type,
      case_description: case_description,
      status_as_of_date: case_status,
      judge_name: judge_name,
      data_source_url: data_source_url
    }
    info
  end

  def case_name(body)
    case_name = body.css('tr')[0]
    case_name.css('span').remove unless case_name.css('span').empty?
    case_name.text.to_s.gsub('Summary', '').gsub('Short Title:', '').gsub(' ', ' ').squeeze(' ').strip
  end

  def case_type(body)
    rows = body.css('table')[0].css('tr')[1..]
    case_type = nil
    rows.each_with_index do |row, index|
      item = row.css('td')[0].text.to_s.strip
      if item == 'Docket No.'
        case_type = rows[index + 1].css('td')[1].text.to_s.strip
        break
      end
    end
    case_type
  end

  def case_judge(body)
    rows = body.css('table')[0].css('tr')[1..]
    judge_name = nil
    rows.each_with_index do |row, index|
      item = row.css('td')[0].text.to_s.strip
      if item == 'Appellate Judges/Justices'
        judge_name = rows[index + 1].css('td')[0].text.to_s.strip
        break
      end
    end
    judge_name = nil if judge_name == '"No Judges Listed"'
    judge_name
  end

  def case_description(body)
    case_description = body.css('table')[0].css('tr')[1]
    case_description.text.to_s.encode("UTF-8", invalid: :replace, replace: "").gsub(/[\u{10000}-\u{FFFFF}]/,'').gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip
  end

  def case_filed_date(body)
    rows = body.css('table')[0].css('tr')[2..]
    activities = []
    rows.each do |row|
      unless row.css('td').count < 4
        activity_date = row.css('td')[0].text.to_s.strip
        activity_desc = row.css('td')[3].text.to_s.strip
        activity_desc = 'Filed By ' + activity_desc unless activity_desc.blank?
        activity_type = row.css('td')[2].text.to_s.strip
        activities << {'activity_date': activity_date, 'activity_desc': activity_desc, 'activity_type': activity_type}
      end
    end
    filed_date = activities.last[:activity_date]
    return if filed_date.blank?
    Date.strptime(filed_date,'%m/%d/%Y')
  end

  def add_info_parse(page)
    body = Nokogiri::HTML.parse(page)
    case_id = body.css('.original_case_id').text
    lower_case_id = lower_case_id(body.css('.original_summary'))
    add_info = {
      court_id: 429,
      case_id: case_id,
      lower_court_name: nil,
      lower_case_id: lower_case_id,
      lower_judge_name: nil,
      lower_judgement_date: nil,
      lower_link: nil,
      disposition: nil
    }
    add_info
  end

  def lower_case_id(body)
    rows = body.css('table')[0].css('tr')[1..]
    lower_case_id = nil
    rows.each_with_index do |row, index|
      item = row.css('td')[0].text.to_s.strip
      if item == 'Trial Court Case ID'
        lower_case_id = rows[index + 1].css('td')[0].text.to_s.strip
        break
      end
    end
    lower_case_id
  end

  def activities_parse(page)
    activities = []
    body = Nokogiri::HTML.parse(page)
    case_id = body.css('.original_case_id').text
    data_source_url = body.css('.original_link_docket').text
    rows = body.css('.original_docket').css('table')[0].css('tr')[2..]
    rows.each do |row|
      unless row.css('td').count < 4
        activity_date = row.css('td')[0].text.to_s.strip
        activity_date = activity_date.blank? ? nil : Date.strptime(activity_date,'%m/%d/%Y')
        activity_desc = row.css('td')[3].text.to_s.strip
        activity_desc = nil if activity_desc.blank?
        activity_desc = 'Filed By ' + activity_desc unless activity_desc.blank?
        activity_type = row.css('td')[2].text.to_s.strip
        activity_type = nil if activity_type.blank?
        activities << {
          court_id: 429,
          case_id: case_id,
          activity_date: activity_date,
          activity_desc: activity_desc,
          activity_type: activity_type,
          file: nil,
          data_source_url: data_source_url
        }
      end
    end
    activities
  end

  def parties_parse(page)
    parties = []
    body = Nokogiri::HTML.parse(page)
    case_id = body.css('.original_case_id').text
    data_source_url = body.css('.original_link_parties').text
    items = body.css('.original_party')
    items.each do |item|
      party_name = item.css('.original_party_name').text
      party_type = item.css('.original_party_type').text
      content = item.css('.original_party_content').css('table')[1].css('tr')[1]
      if content.text.strip == 'No Address found.'
        party_address = nil
        party_city = nil
        party_state = nil
        party_zip = nil
      else
        party_address = content.css('td')[1].text.to_s.strip
        party_address = nil if party_address.blank?
        party_city = content.css('td')[2].text.to_s.strip
        party_city = nil if party_city.blank?
        party_state = content.css('td')[3].text.to_s.strip
        party_state = nil if party_state.blank?
        party_zip = content.css('td')[4].text.to_s.strip
        party_zip = nil if party_zip.blank?
      end
      parties << {
        court_id: 429,
        case_id: case_id,
        is_lawyer: 0,
        party_name: party_name,
        party_type: party_type,
        party_law_firm: nil,
        party_address: party_address,
        party_city: party_city,
        party_state: party_state,
        party_zip: party_zip,
        party_description: nil,
        data_source_url: data_source_url
      }
    end
    parties
  end
end
