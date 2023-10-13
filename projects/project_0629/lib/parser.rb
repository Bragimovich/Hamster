# frozen_string_literal: true

# require_relative '../lib/attorneys_parser'
# require_relative '../lib/scraper'
require_relative '../lib/helper'
require_relative '../lib/normalizer'

class Parser < Hamster::Parser
  DEBUG_SHIFT = 0
  EMPTY_LINES = []
  SQL_OR_COUNTIES = 'select * from usa_administrative_division_counties where state_id = 38';
  SKIPPED = %w(SKIPPED)
  CCC = 'County Circuit Court'
  COUNTIES = %w(
    Baker Benton Clackamas Clatsop Columbia Coos Crook Curry Deschutes Douglas
    Gilliam Grant Harney Hood\ River Jackson Jefferson Josephine Klamath Lake Lane
    Lincoln Linn Malheur Marion Morrow Multnomah Polk Sherman Tillamook Umatilla
    Union Wallowa Wasco Washington Wheeler Yamhill)

  def initialize
    @helper = Helper.new
    @normalizer = Normalizer.new
  end

  def parse_api(source)
    api_json = JSON.parse(source)
    @court_id = @helper.court_id(api_json)
    @fields = @helper.to_hash_of_hashes(api_json["fields"])
    @case_id = @fields["relispt"]["value"].chomp
    {
      info: parse_info(api_json),
      parties: parse_parties(api_json),
      activities: parse_activities(api_json),
      additional_info: parse_additional_info(api_json)
    }
  end

  def parse_pdf(pdf_path)
    io     = open(pdf_path)
    reader = PDF::Reader.new(io)

    pages_text = reader.pages[0,2].map {|el| el.text}.join("\n")
    txt_lines = pages_text.split("\n").reject {|el| el.empty?}
    parse_pdf_parties(txt_lines)
  end

  def parse_info(api_json)
    {
      court_id:               @court_id,
      case_id:                @case_id,
      case_name:              @fields.dig("subjec", "value")&.chomp,
      case_filed_date:        nil,
      case_type:              nil,
      case_description:       nil,
      disposition_or_status:  nil,
      status_as_of_date:      @fields.dig("descri", "value")&.chomp,
      judge_name:             nil,
      lower_court_id:         nil,
      lower_case_id:          nil
    }
  end

  def parse_parties(api_json)
    value = @fields.dig("subjec1", "value")&.chomp
    value&.split(';')&.map do |name|
      {
        court_id:           @court_id,
        case_id:            @case_id,
        party_name:         name.strip,
        party_type:         nil,
        party_description:  nil,
        party_address:      nil,
        party_city:         nil,
        party_state:        nil,
        party_zip:          nil,
        party_law_firm:     nil,
        is_lawyer:          0
      }
    end
  end

  def parse_activities(api_json)
    {
      court_id:       @court_id,
      case_id:        @case_id,
      activity_type:  @fields.dig("type", "value")&.chomp,
      activity_date:  @fields.dig("dated", "value")&.chomp,
      activity_desc:  @helper.activity_desc(@fields),
      file:           API_URL.sub('/api', api_json["downloadUri"])
    }
  end

  def parse_additional_info(api_json)
    {
      court_id:       @court_id,
      case_id:        @case_id
    }
  end

  # ========================== pdf-section ==========================
  def parse_pdf_parties(text)
    court_index = text.find_index {|line| line.delete(' ').upcase[/THESTATEOF|THESUPREME|THEOREGONSUPREME/]}
    docname_index = text.find_index {|line| line.delete(' ').upcase[/BRIEF|MEMORANDUM|PETITIONTOREVIEW|CURIAE/]}
    # text + (text[court_index.next..docname_index.pred] rescue ['xX'*44])

    # party_lines = text[court_index.next..docname_index.pred] rescue EMPTY_LINES
    # res = lower_court_information(party_lines)
    # proper_case_numbers = proper_case_numbers(case_numbers(res))
    # lower_court = lower_court(res)
    #
    # parties = split_to_parties(prepare(party_lines))
    # {
    #   cases:    parse_cases(proper_case_numbers, lower_court),
    #   parties:  parties.map {|el| parse_single_party(el)}
    # }

    table_of_contents_index = text.find_index {|line| line.delete(' ').upcase[/TABLEOF|OFCONTENTS/]} || text.size
    res = text[docname_index..table_of_contents_index.pred]
    att_lines = attorney_lines(res)

    # pp attorneys = split_att(prepare_att(att_lines))
    attorneys = split_att(prepare_att(att_lines))
    parse_attorneys(attorneys)
  end

  def parse_single_party(lines)
    lines = lines.join(',').split(',') if lines.size < 3

    type_start_index = lines.find_index {|line| line[/ppell|esponden|etiti|fendant|terven|pplicant/]}
    type_start_index ||= lines.size

    tail_drop_count = lines.reverse.find_index {|line| !line[/\d|ourt/]}
    type_end_index = lines.size.pred - tail_drop_count
    type_end_index = lines.size if type_end_index < type_start_index
    {
      party_name: lines[0,type_start_index].join('\n'),
      party_type: lines[type_start_index..type_end_index].join('\n'),
      is_lawyer:  0
    }
  end

  def lower_court_information(lines)
    lines.select {|line| line[/\d{2}|ourt|ounty|Board/]}
  end

  def case_numbers(lines)
    lines.join(' ').gsub(',', ' ').split(' ').select {|el| el[/\d{3}|\d-\d/]}
  end

  def proper_case_numbers(cases)
    cases.select {|el| el.match(/^[-A-Z0-9]+$/)}
  end

  def lower_court(lines)
    return "Oregon Land Use Board of Appeals" if lines.find_index {|el| el[/LUBA|Land Use Board/]}
    return "Oregon Workers' Compensation Board" if lines.find_index {|el| el[/WCB|Agency/]}
    return "Public Employees Retirement Board" if lines.find_index {|el| el[/etirement/]}
    return "Oregon Tax Court" if lines.find_index {|el| el[/Tax/]}
    return "Oregon State Bar" if lines.find_index {|el| el[/OSB/]}
    return "Energy Facility Siting Council" if lines.find_index {|el| el[/EFSC/]}

    COUNTIES.each {|county| return "#{county} #{CCC}" if lines.find_index {|el| el[county]}}
    return nil
  end

  def parse_cases(cases, lower_court)
    cases.map do |case_number|
      lower_court_name = court_name(case_number, lower_court)
      {
        lower_case_id:    case_number,
        lower_court_name: lower_court_name
      } unless lower_court_name.nil?
    end.compact
  end

  def court_name(case_number, lower_court)
    return "Oregon Supreme Court" if case_number =~ /S\d{6}/
    return "Oregon Court of Appeals" if case_number =~ /A\d{6}/
    lower_court
  end

  def attorney_lines(lines)
    start_index = lines.find_index {|line| line[/OSB|#|\(\d{6}\)/]} || 1
    end_index = lines.find_index {|line| line[/INDEX|INTRODUCTION|\.{5}|_{40}/]}
    end_index = lines.size unless start_index < end_index.to_i
    res = lines[start_index..end_index.pred].reject {|el| el[/\.{5}/]} rescue EMPTY_LINES
    res.each {|line| line.gsub!(/#\s+/, '#')}
    res.each {|line| line.gsub!(/ OR /, ', OR ') unless line.include?(',')}
    res
  end

  def prepare(lines)
    return EMPTY_LINES if lines.empty?
    # 1. remove first line if it's include THE STATE OF OREGON
    lines.shift if lines.first.delete(' ').upcase.include?('THESTATEOF')
    # 2.1. remove lines without any text_digit information
    lines.select! {|el| el =~ /[0-9a-zA-Z]/}

    return @normalizer.pdf_with_parenthese_or_pipe(lines) if parenthese_or_pipe?(lines)
    lines = remove_left_spaces(lines)
    sorted_lines = lines.sort_by(&:length)
    rectangle_lines = add_right_spaces(sorted_lines)
    return @normalizer.pdf_with_two_columns(lines) if two_columns?(rectangle_lines)
    return @normalizer.other_pdf(lines)

    # return SKIPPED
  end

  def parenthese_or_pipe?(lines)
    text = lines.join.gsub('|', ')')
    text.count(')') - text.count('(') > 1
  end

  # this method gets text (sorted by string length)
  # and cuts it in 4 parts (like Decart does)
  # and calculate ratio of characters in I and II quadrants
  # if text has two columns, it will looks like this:
  #  ______
  # |      \
  # |       \___
  # |           \
  # |____________\
  # and if it has only one columne and centered - like this:
  #      / \
  #     /   \
  #    /     \
  #  _/       \_
  # /___________\
  def two_columns?(lines)
    return true if lines.size < 3
    checking_lines = lines[0,lines.size.div(2)]
    top_left_corner = checking_lines.map {|el| el[0, el.size.div(2)]}.join
    top_right_corner = checking_lines.map {|el| el[el.size.div(2)..]}.join
    ratio = top_right_corner.delete(' ').size / top_left_corner.delete(' ').size.to_f
    ratio < 0.3
  end

  def remove_left_spaces(lines)
    length = lines.map {|el| el.size - el.lstrip.size}.min
    lines.map {|el| el[length..-1]}
  end

  def add_right_spaces(lines)
    length = lines.map(&:size).max
    lines.map {|el| el.ljust(length)}
  end

  def split_to_parties(lines)
    return lines if lines.empty?
    index = lines.find_index{|line| line.size < 4}
    return [lines] if index.nil?
    [lines[0, index]] + split_to_parties(lines[index.next..])
  end

  def prepare_att(lines)
    return EMPTY_LINES if lines.empty?
    return @normalizer.attorneys_gapped(lines) if attorneys_gapped?(lines)
    # return @normalizer.attorneys_not_gapped(lines) unless attorneys_gapped?(lines)

    return EMPTY_LINES
  end

  # --------------- !!! ATTENTION !!! ---------------
  # ---------------- recurrent method ---------------
  def split_att(lines)
    return EMPTY_LINES if lines.empty?
    next_bar_index = lines[1..].find_index {|el| el[/OSB|#\d{6}|\(\d{6}\)|Bar\ No\./]}&.next
    return lines_with_debug_info(lines) if next_bar_index.nil?
    lines_with_debug_info(lines[0,next_bar_index]) + split_att(lines[next_bar_index..])
  end

  def lines_with_debug_info(lines)
    [lines]
    # [lines, "lines = #{lines.size}", '-'*55]
  end

  def attorneys_gapped?(lines)
    gap_count = lines.count { |line| line.lstrip =~ / {5}/ }
    gap_count > 2
  end

  def parse_attorneys(attorneys)
    # pp attorneys, '-'*55
    return EMPTY_LINES if attorneys.nil? or attorneys.empty?
    # 1. find first with all information
    info_index = attorneys.find_index {|att| full_info?(att)} || (attorneys.size.pred - DEBUG_SHIFT) # last element, change it to `attorneys.size.pred` after remove debug lines

    # 2. parse all information
    regional_information = @helper.party_city_state_zip(attorneys[info_index])
    @party_full_info = {
      # 2.1 name
      party_name:         @helper.party_name(attorneys[info_index]),
      # 2.2 type
      party_type:         @helper.party_type(attorneys[info_index]),
      # 2.3 law_firm
      party_law_firm:     @helper.party_law_firm(attorneys[info_index]),
      # 2.4 party_address
      party_address:      @helper.party_address(attorneys[info_index]),
      # 2.8 party_description
      party_description:  @helper.party_description(attorneys[info_index])
      # 2.5 party_city
      # 2.6 party_state
      # 2.7 party_zip
    }.merge!(regional_information)
    # 3. parse preceding attorneys (add all info)
    res = parse_preceding_attorneys(attorneys[0,info_index])
    # 4. repeat till finish
    [res] + parse_attorneys(attorneys[(info_index.next + DEBUG_SHIFT)..])

    # pp "index = #{info_index}"
    # pp attorneys[info_index].map {|el| " "*20 + el}
  end

  def parse_preceding_attorneys(attorneys)
    attorneys.map {|att| parse_preceding_attorney(att)} + [@party_full_info]
  end

  def parse_preceding_attorney(lines)
    @party_full_info.merge(
      {
        party_name:         lines[0],
        party_description:  lines[1..].join("\n")
      })
  end

  def full_info?(att)
    return false unless att.is_a?(Array)
    return false if att.size < 4
    att.find_index {|line| line[/ttorney|OR \d{5}|/]} || false
  end

end
