class WiscCourtsParser < Hamster::Parser
  def initialize(page)
    super
    @html = Nokogiri::HTML(page)
  end

  def parse_main_page
    return {} if @html.css('#mainContent div.error').text.match?(/search did not/)

    case_id   = nil
    case_name = nil
    @html.css('#mainContent h1').each do |heading|
      if heading.text.match?(/Appeal Number/)
        case_id = heading.text.sub('Appeal Number ', '').sub(/ - \w+$/, '').strip
      else
        case_name = heading.text
      end
    end
    case_filed_date    = @html.css('table[6] td div')[-2].text.scan(/\d{2}-\d{2}-\d{4}/).first
    case_filed_date    = correct_date(case_filed_date)
    court_type         = @html.at('#mainContent div.head2').text
    court_id           = court_type.match?(/Supreme Court/) ? 350 : 485
    case_type          = @html.at('table tr[5] td div').text
    status_as_of_date  = @html.at('table tr[3] td[2] div').text
    data_source_url    = "https://wscca.wicourts.gov/caseDetails.do?caseNo=#{case_id}"
    parties_attorneys  = @html.css('table').find { |table| table if table.text.match?(/Side/) && table.text.match?(/Party Name/) }&.css('tr')
    interested_parties = @html.css('table').find { |table| table if table.text.match?(/Title/) && table.text.match?(/Comment/) }&.css('tr')
    parties_attorneys&.shift
    interested_parties&.shift
    party_type = nil
    case_party = []
    parties_attorneys&.each do |people|
      people = people.css('td div').map do |i|
        result = i.text
        result&.empty? ? nil : result
      end

      case people.size
      when 5
        address    = parse_address(people.last)
        party_type = people[2].gsub(/([a-z])([A-Z])/) { "#{$1} #{$2}" }
        case_party << { is_lawyer: 1, party_name: people[3], party_type: party_type, party_address: people[4],
                        party_city: address[:city], party_state: address[:state], party_zip: address[:zip] }
        case_party << { party_name: people[1], party_type: party_type, party_address: people.last,
                        party_city: address[:city], party_state: address[:state], party_zip: address[:zip] }
      when 2
        address = parse_address(people[1])
        case_party << { is_lawyer: 1, party_name: people[0], party_type: party_type, party_address: people[1],
                        party_city: address[:city], party_state: address[:state], party_zip: address[:zip] }
      else
        address = parse_address(people.last)
        case_party << { party_name: people[1], party_type: people[2]&.gsub(/([a-z])([A-Z])/) { "#{$1} #{$2}" },
                        party_address: people.last, party_city: address[:city], party_state: address[:state],
                        party_zip: address[:zip] }
      end
    end

    interested_parties&.each do |people|
      people  = people.css('td div').map(&:text)
      address = parse_address(people[1])
      case_party << { party_name: people[0], party_type: people[2], party_address: people[1],
                      party_city: address[:city], party_state: address[:state], party_zip: address[:zip] }
    end

    if @html.text.match?(/Consolidated Case Numbers/)
      table = @html.css('table').find do |table|
        table if table.text.match?(/Case Number/) && table.text.match?(/Filing Date/)
      end.css('tr')
      table.shift
      cons_details = get_consolidations(table)
    end

    if @html.text.match?(/Circuit Court Case Numbers/)
      table = @html.css('table').find do |table|
        table if table.text.match?(/Case Number/) && table.text.match?(/Circuit Court Judge/)
      end.css('tr')
      table.shift
      additional = get_additional_info(table)
    end

    { court_id: court_id, case_id: case_id, case_name: case_name, case_type: case_type,
      case_filed_date: case_filed_date, status_as_of_date: status_as_of_date, data_source_url: data_source_url,
      case_party: case_party, cons_details: cons_details || [], additional: additional || [] }
  end

  def get_activities
    return {} if @html.css('table').empty? || @html.css('table').nil?

    activities       = []
    activities_cache = []
    table_history    = @html.css('table').find do |table|
      table if table.text.match?(/Filing Date|Anticipated Due Date/)
    end.css('tr')
    table_history.shift
    table_history.each do |line_noko|
      line = line_noko.css('td div').map(&:text)
      next if line.empty?

      if line.size == 1
        activity_desc = line.first.strip
        activities_cache.each { |i| i[:activity_desc] = activity_desc }
        next
      else
        activities += activities_cache
        activities_cache = []
      end

      activity_date = line[2].empty? ? line[3] : line[2]
      activity_date = correct_date(activity_date)
      td_last       = line_noko.css('td').last
      activity_type = line.last
      if td_last.to_html.match?(/href="/)
        if td_last.to_html.split('href=').size > 2
          activities_raw = td_last.at('div').children.map(&:to_html)
          activities_raw.each do |activity|
            next if Nokogiri::HTML(activity).text.empty?

            file          = Nokogiri::HTML(activity).at('a')['href'] if activity.match?(/href=/)
            activity_type = Nokogiri::HTML(activity).text
            activities_cache << { activity_date: activity_date, activity_type: activity_type, file: file }
          end
        else
          file          = td_last.at('a')['href']
          link_text     = td_last.css('a').remove.text
          td_text       = td_last.text.strip
          activity_type = td_text.empty? ? link_text : "#{td_text}; #{link_text}"
          activities_cache << { activity_date: activity_date, activity_type: activity_type, file: file }
        end
      else
        activities_cache << { activity_date: activity_date, activity_type: activity_type }
      end
    end
    activities
  end

  def get_consolidations(table)
    table.map do |line|
      line = line.css('td div').map(&:text)
      date = correct_date(line.last)
      { consolidated_case_id: line[0].strip, consolidated_case_name: line[1], consolidated_case_filled_date: date }
    end
  end

  def get_additional_info(table)
    table.map { |line| { lower_case_id: line[0], lower_judge_name: line.css('td div').map(&:text).last } }
  end

  def list
    @html.css('.resultList > tr > td > div > a').map(&:text)
  end

  def get_link_pdf
    "https://www.wicourts.gov" + @html.at('.table-bordered tr td a')['href']
  end

  private

  def parse_address(address)
    return {} if address.nil? || address.match?(/confidential/i)

    parsed_address         = {}
    address                = address.gsub(' ', '')
    parsed_address[:zip]   = address.strip.match(/\d+-\d+$|\d+$/).to_s
    address                = address.sub(parsed_address[:zip], '')
    parsed_address[:state] = address.strip.match(/[A-Z]{2}$/).to_s
    address                = address.sub(parsed_address[:state], '')
    parsed_address[:city]  = address.strip.match(/[A-Z]+\D+$/).to_s.sub(',', '')
    parsed_address
  end

  def correct_date(date)
    return unless date

    date = date.split('-')
    day  = date.delete_at(1)
    date.unshift(day).join('-')
  end
end
