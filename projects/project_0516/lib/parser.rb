# frozen_string_literal: true

require_relative '../lib/attorneys_parser'
require_relative '../lib/scraper'

LINK_NAMES = ['All Documents For This Case ', ' Docket Sheet', 'Next »']
NEXT = 1
PREV = -1
NO_LOWER_COURT_CASES = [] # an empty array

class Array
  def find_by_offset(element, offset = 0)
    self[find_index(element) + offset]
  rescue
  end
end

class Parser < Hamster::Parser
  def parse_links(source)
    page = Nokogiri::HTML source.body
    links = page.css('a').map { |el| el["href"] if el.text.in?(LINK_NAMES) }.compact
    links.select {|el| el.include?('dockets.php?') || el.include?('search-results.php?')}
  end

  # -------------------- !!! ATTENTION !!! --------------------
  # =============== Next Page recurrent method ================
  def parse_dockets_info(source)
    page = Nokogiri::HTML source
    # table = page.css('div.search-container')
    # tr = table&.css('div.row')[2..]
    list_group = page.css('div.list-group')
    tr = list_group&.css('div.row')[2..-2]

    return [] if tr.nil?
    res = tr.map do |row|
      td = row.text.split(' Filed By: ')
      {
        activity_type:  td[0],
        activity_date:  td[0].size>4 ? Date.parse(td[1].split[-1]) : nil,
        activity_desc:  td[1].nil? ? nil : td[1].split[..-2].join(' '),
        file:           activity_file_link(row)
      }
    end.reverse
    res = (parse_dockets_info(next_page(source)) + res) if has_next?(source)
    res
  end

  def activity_file_link(row)
    row.css('a').empty? ? nil : URI.join(URL, row.css('a').first["href"]).to_s
  end

  def has_next?(source)
    source.include?('"Next">Next')
  end

  def next_page(source)
    next_page_link = source.split('"Next">Next')[0].split('"')[-2]
    Scraper.new.get_source(next_page_link).body
  end
  # ============= Next Page recurrent method ends =============

  def dockets_source_url(source)
    page = Nokogiri::HTML source
    page.css('div.search_documents').css('a')[0]["href"]
  end

  def parse_txt(text)
    text_lines = prepare(text)
    {
      info: parse_info(text_lines),
      parties: parse_parties(text_lines),
      activities: parse_activities(text_lines),
      additional_info: parse_additional_info(text_lines)
    }
  end

  def prepare(text)
    text.sub!("No\n\n\f", "\f")
    text.sub!("Yes\n\n\f", "\f")
    lines = text.gsub("\n\n\f","\f\n").split("\n").reject {|el| el.empty?}

    attorney_for_index = lines.find_index {|el| el.start_with?('Attorney for ') && el.include?("\f")}
    unless attorney_for_index.nil?
      page_number_to_insert = lines[attorney_for_index].split[-1]
      lines[attorney_for_index].slice!(/\d+[\f]$/)
      lines.insert(attorney_for_index.next, "#{page_number_to_insert}\f")
    end

    last_page_number = lines[-1].to_i
    (1..last_page_number.pred).each do |page_number|
      page_number_position = lines.find_index("#{page_number}\f")
      lines.slice!(page_number_position, 2)
    end
    lines
  end

  def parse_info(text_lines)
    court_id =  text_lines[1].include?('SUPREME') ? 334 :
                text_lines[1].include?('Appeals') ? 446 : 77777
    case_id = text_lines.find_by_offset('Case Number:', NEXT)
    case_name = text_lines.find_by_offset('Case Number:', PREV)
    case_filed_line = text_lines[text_lines.find_index {|el| el.start_with?('Filed:')}]
    case_filed_date = DateTime.strptime(case_filed_line, 'Filed: %m-%d-%Y @ %H:%M:%S')

    info_start_index = text_lines.find_index('Case Type:')
    info_end_index = text_lines.find_index('Docket Date:').pred
    info_lines = text_lines[info_start_index..info_end_index]

    docket_start_index = info_end_index.next
    docket_end_index = text_lines.find_index('History').pred
    docket_lines = text_lines[docket_start_index..docket_end_index]
    docket_lines += text_lines[..docket_start_index].reverse

    is_closed = text_lines.find_by_offset('Case Closed:', NEXT)
    lower_case_id = get_lower_case_id(text_lines)
    info =  {
      court_id:               court_id,
      case_id:                case_id,
      case_name:              case_name,
      case_filed_date:        docket_date(docket_lines) || case_filed_date,
      case_type:              case_type(info_lines),
      case_description:       case_description(info_lines),
      disposition_or_status:  nil,
      status_as_of_date:      is_closed.eql?('Yes') ? 'Closed' : 'Active',
      judge_name:             nil,
      lower_court_id:         nil,
      lower_case_id:          lower_case_id }
  end

  def docket_date(lines)
    index = lines.find_index {|el| el =~ /\d{2}-\d{2}-\d{4}/}
    Date.strptime(lines[index], '%m-%d-%Y') rescue nil
  end

  def case_type(lines)
    index = lines.find_index {|el| el[-1].eql?(')')} || 0
    lines[index]
  end

  def case_description(lines)
    index = lines.find_index {|el| el.upcase.eql?(el) && el.index(/[A-Z]/)} || 0
    lines[index..].join(' ')
  end

  def parse_parties(text_lines)
    parties = []
    # ======================= Parties block =======================
    party_start_index = text_lines.find_index('Parties') + 3
    party_end_index = text_lines.find_index('Attorneys').pred
    # return parties unless text_lines[party_start_index.pred].eql?('Role')

    party_start_index -= 1 if text_lines[party_start_index].include?("Appell")
    party_start_index -= 1 if text_lines[party_start_index].start_with?(/Role.+/)
    curr_index = party_start_index
    while curr_index < party_end_index do
      next_index = curr_index + text_lines[curr_index..party_end_index].find_index {|el| el.include?("Appell")}
      party_name = text_lines[curr_index..next_index.pred].join(' ')

      parties << {party_name:         party_name.sub('Role ', text_lines[curr_index.pred] + " "),
                  party_type:         text_lines[next_index],
                  party_description:  nil,
                  party_address:      nil,
                  party_city:         nil,
                  party_state:        nil,
                  party_zip:          nil,
                  party_law_firm:     nil,
                  is_lawyer:          0}

      curr_index = next_index.next
    end

    # ====================== Attorneys block ======================
    attorney_start_index = text_lines.find_index('Attorneys').next
    attorney_end_index = text_lines.size - 2
    return parties unless text_lines[attorney_start_index].start_with?('Attorney for')

    curr_index = attorney_start_index
    while curr_index < attorney_end_index do
      next_index = curr_index
      loop do
        offset = text_lines[next_index.next..attorney_end_index].find_index {|el| el.start_with?('Attorney for')}
        next_index = offset.nil? ? attorney_end_index.next : next_index + offset.next
        break if next_index > attorney_end_index
        break if !text_lines[next_index.next].include?('@')
      end

      parties += AttorneysParser.new(text_lines[curr_index..next_index]).parse if (next_index - curr_index)>2

      curr_index = next_index
    end
    parties
  end

  def parse_activities(text_lines)
    start_index = text_lines.find_index {|el| el.start_with?('1 - ')}
    end_index = text_lines.find_index('Financial').pred
    activities = get_activities(text_lines[start_index..end_index])
  end

  # !!!======================== recurrent method ========================!!!
  def get_activities(text_lines)
    last_index = text_lines.rindex {|el| el.start_with?(/\d+ - |RESPONSE/)}
    last_index -= 1 while text_lines[last_index.pred].start_with?(/\d+ - |RESPONSE/)
    return get_activity(text_lines) if last_index.zero?
    get_activities(text_lines[..last_index.pred]) + get_activity(text_lines[last_index..])
  end


  def get_activity(lines)
    date_index = lines.find_index {|el| el.start_with?('Filed:')}
    desc_index = lines.find_index {|el| el.start_with?('BY :')}.next
    desc_index += 1 if lines[desc_index].eql?(lines[desc_index].to_s.upcase)
    date_text = lines[date_index].split[1]
    activity_type_text = lines[..date_index.pred].join(' ')
    [{
      activity_type: remove_date_from_activity_type(activity_type_text),
      activity_date: date_text.nil? ? nil : DateTime.strptime(date_text, '%m-%d-%Y').to_date,
      activity_desc: lines[desc_index..-2].join("\n"),
      file: nil
    }]
  end

  def remove_date_from_activity_type(str)
    return str[..-12] if str =~ /\) \d\d-\d\d-\d\d\d\d$/
    return str[..-14] if str =~ /\) - \d\d-\d\d-\d\d\d\d$/
    str
  end

  def parse_additional_info(text_lines)
    start_index = text_lines.find_index('L o w e r C o u r t N u m b e r(s)').next
    end_index = text_lines.find_index('Tracking/Argue').pred
    additional_info = get_additionals(text_lines[start_index..end_index])
  end

  def get_additionals(text_lines)
    last_index = text_lines.rindex {|el| el.eql?('Location:')}
    # last_index -= 1 while text_lines[last_index.pred].start_with?(/\d+ - |RESPONSE/)
    return NO_LOWER_COURT_CASES if last_index.nil?
    return get_additional(text_lines) if last_index.zero?
    get_additionals(text_lines[..last_index.pred]) + get_additional(text_lines[last_index..])
  end

  def get_additional(text_lines)
    judge_index = text_lines.find_index {|el| el.start_with?('Judge:')}
    case_number_index = text_lines.find_index {|el| el.start_with?('Case #:')}
    [{
      lower_court_name:     text_lines[1..judge_index.pred].join("\n"),
      lower_case_id:        text_lines[case_number_index.next..].join("\n"),
      lower_judge_name:     text_lines[judge_index.next..case_number_index.pred].join("\n"),
      lower_judgement_date: nil,
      lower_link:           nil,
      disposition:          nil
      }]
  end

  def get_lower_case_id(text_lines)
    res = text_lines.find_by_offset('Case #:', NEXT)
    return nil if res.nil?
    res = text_lines.find_by_offset('Case #:', PREV) if !(res =~ /\d/)
    res = 'ALERT' if !(res =~ /\d/)
    res
  end
end
