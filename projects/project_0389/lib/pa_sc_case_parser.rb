class PaScCaseParser < Hamster::Parser
  def initialize(**page)
    super
    if page[:html]
      @html = Nokogiri::HTML(page[:html])
    elsif page[:pdf]
      @pdf  = PDF::Reader.new(page[:pdf]).pages
    end
    @additional_info = []
  end

  def parse_start_info
    html = @html.css('div.table-wrapper table.table tbody')
    return [] if html.empty?

    html.css('tr').map do |i|
      link = "https://ujsportal.pacourts.us#{i.children.last.at('div a')['href']}".gsub(' ', '%20')
      info = { case_name: i.children[4].text, case_filed_date: correct_date(i.children[6].text), data_source_url: link }
      { case_id: i.children[2].text, source_link: link, info: info }
    end
  end

  def parse_info
    page_one    = @pdf[0].text
    case_id     = page_one.match(/(?<=Docket Number:)(.+?)(?=Page)/m).to_s.strip
    case_type   = page_one.match(/(?<=Case Category:)(.+?)(?=Case Type)/m).to_s.strip
    desc        = page_one.match(/(?<=Case Type\(s\):)(.+?)(?=CONSOLIDATED CASES)/m).to_s.strip
    status_desp = page_one.match(/(?<=Initiating Document:)(.+?)(?=Case Status:)/m).to_s.strip
    full_name   = page_one.match(/(?<=CAPTION)(.+?)(?=CASE INFORMATION)/m).to_s.strip
    status      = page_one.match(/(?<=Case Status:)(.+?)(?=Journal Number)/m).to_s.strip

    page_two  = @pdf[1]&.text
    status    = page_two.match(/(?<=Case Status:)(.+?)(?=Journal Number)/m).to_s.strip  if status.empty? && page_two
    case_type = page_two.match(/(?<=Case Category:)(.+?)(?=Case Type)/m).to_s.strip     if case_type.empty? && page_two
    desc      = page_two.match(/(?<=Case Type\(s\):)(.+?)(?=CONSOLIDATED)/m).to_s.strip if desc.empty? && page_two

    { case_id: case_id, case_description: desc&.gsub(/ {2,}/, ' '), status_as_of_date: status,
      disposition_or_status: status_desp, case_type: case_type, case_full_name: full_name }
  end

  def parse_additional_info
    trial     = false
    appellate = false
    @pdf.each do |page|
      if page.text.match?(/INTERMEDIATE APPELLATE COURT INFORMATION/)
        appellate = true
        parse_page_intermediate(page)
      elsif appellate
        parse_page_intermediate(page)
      end

      if @additional_info.empty? && page.text.match?(%r{AGENCY/TRIAL COURT INFORMATION})
        trial = true
        parse_page_trial(page)
      elsif trial
        parse_page_trial(page)
      end
    end
    @additional_info
  end

  def parse_party
    party = []
    @pdf.each do |page|
      next unless page.text.match?(/COUNSEL INFORMATION/)

      parse_representing_address(page, party)
      parse_representing(page, party)
      parse_attorney(page, party)
    end
    party
  end

  def parse_consolidations
    page_one = @pdf[0].text
    block    = page_one.match(/(?<=RELATED CASES)(.+?)(?=COUNSEL INFORMATION)/m).to_s.strip
    return [] if block.empty? || !block.match?(/Consolidated/)

    block.scan(/\d{1,3}\s[A-Z]{2,3}\s\d{0,4}(?=\s*Consolidated)/)
  end

  def parse_activities
    activities = []
    @pdf.each do |page|
      next unless page.text.match?(/DOCKET ENTRY/)

      docket_entry = page.text.match(/DOCKET ENTRY.+/m).to_s
      blocks = docket_entry.scan(/(?=[A-Z][a-z]{2,8}\s\d{1,2}.?\s\d{4} {3,})(.+?)(?=[A-Z]\w{2,8}\s\d{1,2}.{1,2}\d{4}|Neither the Appellate Courts|CROSS COURT ACTIONS)/m)
      blocks.flatten.each do |i|
        activity = {}
        first_line = i.match(/^[A-Z].+\n/).to_s.strip
        activity[:activity_date] = first_line.match(/[A-Z][a-z]{2,8}\s\d{1,2}.?\s\d{4}/).to_s.strip
        desc                     = first_line.match(/\s{3,}.{9,}$/).to_s.strip
        activity[:activity_desc] = desc if desc.present?
        i.sub!(first_line, '')&.lstrip!
        second_line = i.match(/^[A-Z].+\n/).to_s.strip.split(/ {2,}/)
        if second_line.size == 2
          activity[:activity_type] = second_line.at(0)
        elsif second_line.size == 3
          activity[:activity_type] = second_line.at(1)
        end
        activities << activity if activity[:activity_desc] || activity[:activity_type]
      end
    end
    activities
  end

  private

  def parse_representing(page, party)
    page.text.scan(/(?<=Representing:)(.+?)(?=Pro Se:)/m).flatten.each do |people|
      name_type = people.split(',')
      type      = name_type.pop.strip
      type&.gsub!("\n", ' ')&.gsub!(/\s{2,}/, ' ')
      party << { party_name: name_type.join(',').strip, party_type: type}
    end
  end

  def parse_representing_address(page, party)
    page.text.scan(/(?<=Pro Se:)(.+?)(?=IFP Status:)/m).flatten.each do |people|
      next unless people.match?(/Pro Se:/)

      name      = people.match(/(?=^)(.+?)(?=Address:)/m).to_s.strip
      name_type = people.match(/(?<=Pro Se:)(.+?)(?=Pro Se:)/m).to_s.strip
      raw_type  = name_type.match(/,\s+[\w\s-]+$/).to_s
      type      = raw_type.sub(/^,\s+/, '')
      type&.gsub!("\n", ' ')&.gsub!(/\s{2,}/, ' ')
      name      = name_type.sub(raw_type, '') if name&.empty?
      address   = parse_address(people)
      party << { party_name: name, party_type: type}.merge(address)
    end
  end

  def parse_attorney(page, party)
    page.text.scan(/(?=Attorney:)(.+?)(?=IFP Status:)/m).flatten.each do |people|
      name_firm = people.match(/(?<=Attorney:)(.+?)(?=Address:)/m).to_s.strip
      type      = people.match(/(?<=Representing:)(.+?)(?=Pro Se:)/m).to_s.strip.match(/,\s+[\w\s-]+\z/).to_s.sub(',', '').strip
      type&.gsub!("\n", ' ')&.gsub!(/\s{2,}/, ' ')
      firm    = name_firm.match(/\s{3,}[A-Za-z].+$/).to_s.strip
      firm    = nil if firm.empty?
      name    = name_firm.match(/^\w.+/).to_s.strip
      address = parse_address(people)
      party << { party_name: name, party_type: type, party_law_firm: firm, is_lawyer: true }.merge(address)
    end
  end

  def parse_address(raw_address)
    address = raw_address.match(/(?<=Address:)(.+?)(?=Phone No:|Receive Mail:)/m).to_s.strip
    adr_end = address.match(/[A-Z][\w -]+, +[A-Z]{2} +\d+-?\d+\z/m).to_s.strip
    city    = adr_end.match(/^.+[a-z]+/).to_s
    zip     = adr_end.match(/[\d|\-]+$/).to_s
    state   = adr_end.match(/[A-Z]{2}/).to_s
    address.gsub!(/ {2,}/, ' ')
    { party_address: address, party_city: city, party_state: state, party_zip: zip }
  end

  def parse_page_intermediate(page)
    page.text.scan(/(?=Court Name:)(.+?)(?<=Referring Court:)/m).flatten.each { |i| save_additional_intermediate(i) }
  end

  def parse_page_trial(page)
    page.text.scan(/(?=Court Below:)(.+?)(?<=Order Type:)/m).flatten.each { |i| save_additional_trial(i) }
  end

  def save_additional_intermediate(item)
    case_id = item.match(/(?<=Docket Number:)(.+?)(?=Date of Order:)/m).to_s.strip
    case_id = case_id.match(/^.+\s{4,}/).to_s.strip if case_id.match?(/\s{4,}/m)
    court   = item.match(/(?<=Court Name:)(.+?)(?=Docket Number:)/m).to_s.strip
    judge   = item.match(/(?<=Judge\(s\):)(.+?)(?=Intermediate Appellate Court Action:)/m).to_s.strip.gsub(/ {2,}/, ' ')
    unless case_id.empty? && court.empty? && judge.empty?
      @additional_info << { lower_court_id: 486, lower_case_id: case_id, lower_court_name: court, lower_judge_name: judge }
    end
  end

  def save_additional_trial(item)
    case_id = item.match(/(?<=Docket Number:)(.+?)(?=Judge\(s\):)/m).to_s.strip
    case_id = case_id.match(/^.+\s{4,}/).to_s.strip if case_id.match?(/\s{4,}/m)
    court   = item.match(/(?<=Court Below:)(.+?)(?=County:)/m).to_s.strip
    judge   = item.match(/(?<=Judge\(s\):)(.+?)(?=OTN:|$)/m).to_s.strip.gsub(/ {2,}/, ' ')
    unless case_id.empty? && court.empty? && judge.empty?
      @additional_info << { lower_court_id: 1001, lower_case_id: case_id, lower_court_name: court, lower_judge_name: judge }
    end
  end

  def correct_date(date)
    date  = date.split('/')
    month = date.shift
    day   = date.shift
    "#{date[0]}-#{month}-#{day}".to_date
  end
end
