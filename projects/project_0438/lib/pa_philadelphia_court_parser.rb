class PaPhiladelphiaCourtParser < Hamster::Parser
  def initialize(**page)
    super
    if page[:html]
      @html = Nokogiri::HTML(page[:html])
    elsif page[:pdf]
      @pdf = open(page[:pdf])&.size.to_i < 100 ? nil : PDF::Reader.new(page[:pdf])
    end
  end

  def parse_link
    html = @html.css('div.table-wrapper table.table tbody')
    html.css('tr').map { |tr| "https://ujsportal.pacourts.us#{tr.children.last.at('div a')['href']}".gsub(' ', '%20') }
  end

  def parse_start_info
    html = @html.css('div.table-wrapper table.table tbody')
    return [] if html.empty?

    html.css('tr').map do |i|
      docket_sheet  = "https://ujsportal.pacourts.us#{i.children.last.at('div a')['href']}".gsub(' ', '%20')
      court_summary = "https://ujsportal.pacourts.us#{i.children.last.css('div a').last['href']}".gsub(' ', '%20')
      info          = { case_name: i.children[4].text, case_filed_date: correct_date(i.children[6].text),
                        data_source_url: docket_sheet }
      { case_id: i.children[2].text, court_summary: court_summary, source_link: docket_sheet, info: info }
    end
  end

  def parse_info
    return unless @pdf

    page_one   = @pdf.pages[0].text
    case_id    = page_one.match(/(?<=Docket Number:)(.+?)(?=\n)/m).to_s.strip
    case_type  = page_one.match(/(?<=Docket Number:)(.+?)(?=Commonwealth of Pennsylvania)/m).to_s.strip.gsub(case_id, '').strip.match(/\s{2,}.+$/).to_s.strip
    info_block = page_one.match(/(?<=STATUS INFORMATION)(.+)/m).to_s.strip.split("\n")
    judge_name = page_one.match(/(?<=Judge Assigned:)(.+?)(?=Date Filed:)/m).to_s.strip.presence
    if case_status = info_block.find { |i| i.match?(/Case Status:/) }
      index_status = info_block.index(case_status)
      status_date  = info_block.empty? ? nil : info_block[index_status].match(/(?<=Case Status:)(.+?)(?=Status Date)/m).to_s.strip
      status       = info_block[index_status + 1].match(/\s{2}[A-Za-z].+$/).to_s.strip if info_block[index_status + 1] && !info_block[index_status + 1]&.empty? && info_block[index_status + 1].match?(/[A-Za-z]/)
      status       = info_block[index_status + 2].match(/\s{2}[A-Za-z].+$/).to_s.strip if status.nil? && (info_block[index_status + 2]&.match?(/^\s+\d{2}\/\d{2}\/\d{4}\s+\w/) || info_block[index_status + 1]&.match?(/^\s+\d{2}\/\d{2}\/\d{4}$/))
    end
    status      = status&.empty? ? nil : status
    status_date = status_date&.empty? ? nil : status_date
    case_type   = case_type&.empty? ? nil : case_type

    if status.nil? && status_date.nil?
      page_two   = @pdf.pages[1].text
      info_block = page_two.match(/(?<=DOCKET)(.+)/m).to_s.strip.split("\n")

      if case_status = info_block.find { |i| i.match?(/Case Status:/) }
        index_status = info_block.index(case_status)
        status_date  = case_status.match(/(?<=Case Status:)(.+?)(?=Status Date)/m)&.to_s&.strip
        status       = info_block[index_status + 1].match(/\s{2}[A-Za-z].+$/).to_s.strip unless info_block[index_status + 1].empty?
        status       = info_block[index_status + 2].match(/\s{2}[A-Za-z].+$/).to_s.strip if status.nil? && info_block[index_status + 2].match?(/^\s+\d{2}\/\d{2}\/\d{4}\s+\w/)
      end
    end
    status      = status&.empty? ? nil : status
    status_date = status_date&.empty? ? nil : status_date
    case_type   = case_type&.empty? ? nil : case_type

    if status.nil? && status_date.nil? && page = @pdf.pages.find { |i| i.text.match?(/(?<=STATUS INFORMATION)(.+)/m) }&.text
      info_block = page.match(/(?<=STATUS INFORMATION)(.+)/m).to_s.strip.split("\n")
      if case_status = info_block.find { |i| i.match?(/Case Status:/) }
        index_status = info_block.index(case_status)
        status_date  = case_status.match(/(?<=Case Status:)(.+?)(?=Status Date)/m)&.to_s&.strip
        status       = info_block[index_status + 1].match(/\s{2}[A-Za-z].+$/).to_s.strip unless info_block[index_status + 1].empty?
        status       = info_block[index_status + 2].match(/\s{2}[A-Za-z].+$/).to_s.strip if status.nil? && info_block[index_status + 2].match?(/^\s+\d{2}\/\d{2}\/\d{4}\s+\w/)
      else
        page_num = nil
        @pdf.pages.each_with_index do |page, idx|
          next if page_num || !page.text.match?(/(?<=STATUS INFORMATION)(.+)/m)
          page_num = idx + 1 if page.text.match?(/(?<=STATUS INFORMATION)(.+)/m)
        end
        case_status = @pdf.pages[page_num].text

        info_block = case_status.strip.split("\n")
        if case_status = info_block.find { |i| i.match?(/Case Status:/) }
          status_date  = case_status.match(/(?<=Case Status:)(.+?)(?=Status Date)/m)&.to_s&.strip
          index_status = info_block.index(case_status)
          status       = info_block[index_status + 1].match(/\s{2}[A-Za-z].+$/).to_s.strip unless info_block[index_status + 1].empty?
          status += ' ' + info_block[index_status + 2].match(/\s{2}[A-Za-z].+$/).to_s.strip if status && !info_block[index_status + 2].empty? && !info_block[index_status + 2].match?(/^\s+\d{2}\/\d{2}\/\d{4}\s+\w/)
          status += ' ' + info_block[index_status + 3].match(/\s{2}[A-Za-z].+$/).to_s.strip if status && !info_block[index_status + 3].empty? && !info_block[index_status + 3].match?(/^\s+\d{2}\/\d{2}\/\d{4}\s+\w/)
          status = info_block[index_status + 2].match(/\s{2}[A-Za-z].+$/).to_s.strip if status.nil? && info_block[index_status + 2].match?(/^\s+\d{2}\/\d{2}\/\d{4}\s+\w/)
        end
      end
    end
    status      = status&.empty? ? nil : status
    status_date = status_date&.empty? ? nil : status_date
    case_type   = case_type&.empty? ? nil : case_type

    { case_id: case_id, status_as_of_date: status_date, case_type: case_type,
      disposition_or_status: status, judge_name: judge_name }
  end

  def parse_case_party
    pages        = @pdf.pages
    case_parties = []
    allias_name  = nil
    address      = nil
    skip         = true
    pages.each do |page|
      next if skip && !page.text.match?(/DEFENDANT INFORMATION|REMITTER INFORMATION|CASE PARTICIPANTS|CHARGES|CPCMS /m)

      if defendant_block = page.text.match(/(?<=DEFENDANT INFORMATION|REMITTER INFORMATION)(.+?)(?=CASE PARTICIPANTS|CHARGES|CPCMS )/m)
        skip = false
        defendant_block = defendant_block.to_s
        allias_name = defendant_block.match(/(?<=Alias Name)(.+$)/m)
        allias_name = allias_name.to_s.strip.downcase.gsub(',', '').split(' ') if allias_name
        address_raw = defendant_block.match(/(?<=Zip:)(.+?)(?=Alias Name)/m).to_s.strip
        address     = parse_adress(address_raw)
      end

      if name_block = page.text.match(/(?<=CASE PARTICIPANTS)(.+?)(?=BAIL INFORMATION|CHARGES|ATTORNEY|CPCMS )/m)
        skip = false
        name_type = name_block.to_s.split("\n").map(&:presence).compact
        name_type.delete_if { |item| item.match?(/Participant|Name/) }
        if name_type.size > 2 && name_type[0].strip.size < 30 && name_type[1].strip.size < 30
          name = name_type.delete_at(1)
          name_type[0] += name
        end
        name_type.each do |item|
          type = item.match(/^.+\s{3,}/).to_s.strip
          name = item.match(/\s{3}.+$/).to_s.strip
          case_parties << { party_name: name, party_type: type } unless type.empty? && name.empty?
        end
        case_parties.delete_if { |i| i[:party_name].match?(/COMMONWEALTH/) }
        if allias_name
          case_party = case_parties.find do |i|
            next unless i[:party_name].presence

            party_name = i[:party_name].downcase.gsub(',', '').split(' ')
            (allias_name & party_name).any?
          end
          index_address = case_parties.index(case_party)
          case_parties[index_address].merge!(address) if index_address
        end
      end

      next unless common_attorney = page.text.match(/(?<=COMMONWEALTH INFORMATION)(.+?)(?=ENTRIES|CPCMS )/m)

      case_parties.delete_if { |party| party[:party_name].empty? && party[:party_type].match?(/COMMONWEALTH INFORMATION/) }
      common_attorney = common_attorney.to_s.split("\n").map(&:presence).compact
      common_attorney.delete_at(0) unless common_attorney[0].match?(/Name:/)
      common   = []
      attorney = []
      common_attorney.each do |line|
        column_length = get_column_length(line)
        common   << line[0..column_length].presence
        attorney << line[column_length + 1..150].presence
      end
      party = parse_party(common.compact)
      case_parties << party if party
      party = parse_party(attorney.compact)
      case_parties << party if party
      return case_parties.each_with_index { |i, idx| i.each { |key, value| case_parties[idx][key] = nil if value.empty? } }
    end
    case_parties.each_with_index { |i, idx| i.each { |key, value| case_parties[idx][key] = nil if value.empty? } }
  end

  def parse_activities
    pages = @pdf.pages
    activities = []
    pages.each do |page|
      next unless page.text.match?(/ENTRIES/m)

      activities_raw = page.text.match(/(?<=ENTRIES)(.+?)(?=PAYMENT|CASE FINANCIAL|CPCMS )/m).to_s.split("\n\n\n")
      activities_raw.delete_if { |i| !i.present? }
      activities_raw.delete_at(0) if activities_raw.size > 1
      replace_strs = /Sequence Number|CP Filed Date|Document Date|Filed By|Issue Date|Service Type|Status Date|Service Status|Service To|Service By/
      activities_raw[0].gsub!(replace_strs, '') if activities_raw.size == 1
      activities_raw.delete_if { |i| !i.present? }

      activities_raw.each do |activity|
        activity = activity.split("\n")
        activity.delete_if { |i| !i.present? }
        next unless activity[0].match?(/\d{2}\/\d{2}\/\d{4}/)

        date = correct_date(activity[0].match(/\d{2}\/\d{2}\/\d{4}/).to_s)
        decs = activity[0].match(/\s{3,}[A-Za-z].+$/).to_s.strip
        if activity.size == 3
          decs += ' ' + activity[1].strip
          type = activity[2].strip
        elsif activity.size > 3
          decs_raw = []
          type_raw = []
          activity[1..-1].each { |str| str.match?(/^\s{5,}.+/) ? decs_raw << str : type_raw << str }
          decs += ' ' + decs_raw.map(&:strip).join(' ')
          type = type_raw.join(' ').strip
        else
          type = activity[1]&.strip
        end
        type = nil if type&.empty?
        decs.lstrip!
        decs = nil unless decs.present?
        activities << { activity_date: date, activity_decs: decs, activity_type: type }
      end
    end
    activities
  end

  private

  def get_column_length(str)
    column_length = str.match(/^\s{0,}\w.{1,57}\s{3,}\w/).to_s.size
    column_length = 0 if str.match(/^\s{62,}/).to_s.size > 62
    column_length.zero? ? 62 : column_length - 2
  end

  def parse_party(strs)
    return nil if strs.empty? || !strs[0].match(/(?<=Name:).+/).to_s.present?

    name = strs[0].match(/(?<=Name:).+/).to_s.strip
    if strs[2].match?(/\d{4,}\s+Supreme Court No:/) && strs[3].match?(/Supreme Court No:/)
      strs[2].sub!('Supreme Court No:', '' )
    end
    if strs[3].match?(/Supreme Court No:/) && strs[2].match?(/[a-zA-Z]/)
      name += " #{strs[1].strip}"
      type = strs[2].strip
    elsif strs[4].match?(/Supreme Court No:/) && strs[2].match?(/[a-zA-Z]/) && strs[3].match?(/\d{4,}/)
      name += " #{strs[1].strip}"
      type = strs[2].strip
    else
      type = strs[1].strip
    end
    party = { party_name: name, party_type: type }
    idx   = strs.index(strs.find { |line| line.match?(/Address:/) })
    return party if strs[idx + 1].nil?

    idx_end = strs.index(strs.find { |line| line.match?(/Representing:/) })
    if (idx_end && (idx_end - idx) == 4) || (idx_end.nil? && strs[idx + 1] && strs[idx + 2] && strs[idx + 3])
      address_start = strs[idx + 1].strip
      address_start += " #{strs[idx + 2].strip}"
      address_finish = strs[idx + 3].strip
    elsif idx_end && (idx_end - idx) == 3 || (idx_end.nil? && strs[idx + 1] && strs[idx + 2])
      address_start  = strs[idx + 1].strip
      address_finish = strs[idx + 2].strip
    elsif !strs[idx + 1].match?(/Representing:/)
      address_finish = strs[idx + 1].strip
    end
    address = parse_adress(address_start, address_finish)
    party.merge(address)
  end

  def parse_adress(address_start = nil, address)
    return {} if address.nil? || address.empty?

    party_city  = address.match(/^.+(?=[A-Z]{2})/).to_s.sub(',', '').rstrip
    party_state = address.match(/[A-Z]{2}/).to_s
    party_zip   = address.match(/\d+$/).to_s
    address     = address_start + ' ' + address if address_start
    { party_address: address, party_city: party_city, party_state: party_state, party_zip: party_zip }
  end

  def correct_date(date)
    date  = date.split('/')
    month = date.shift
    day   = date.shift
    "#{date[0]}-#{month}-#{day}".to_date
  end
end
