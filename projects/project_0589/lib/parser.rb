# frozen_string_literal: true

class Parser < Hamster::Parser

  COURT_ID = '433'

  def get_pdf_links(page)
    @t_head = page.css('#datatable th').map{|e| e.text.downcase.strip}
    @th_index = t_head.index('download')
    page.css("#datatable tr td[#{th_index + 1}] a").map{|e| e['href']}.uniq
  end

  def initialize_values(pdf_path, run_id)
    @reader = PDF::Reader.new(open(pdf_path))
    @document = reader.pages.map{|page| page.text.scan(/^.+/)}.flatten
    @run_id = run_id
  end

  def parse_case_info(page, pdf_link,year)
    table_rows = page.css('#datatable tr')[1..]
    row = table_rows.select{|e| e.css('td')[th_index].at_css('a')['href'] == pdf_link}.first
    opinion_date = get_info_value(row, 'opinion date')
    case_info_array = []
    @case_ids = get_info_value(row, 'case number').split
    @case_ids =  @case_ids.reject { |e| (e.exclude? '-') }
    case_ids.each do |case_id|
      data_hash = {}
      data_hash[:court_id]          = COURT_ID
      data_hash[:case_id]           = case_id
      data_hash[:case_name]         = get_info_value(row, 'case name')
      data_hash[:status_as_of_date] = get_info_value(row, 'disposition')
      data_hash[:judge_name]        = get_info_value(row, 'authoring judge')
      data_hash[:lower_case_id]     = get_lower_case_id
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash[:data_source_url]   = "https://www.la2nd.org/opinions/?opinion_year=#{year}"
      data_hash                     = mark_empty_as_nil(data_hash)
      case_info_array << data_hash
    end
    [case_info_array,opinion_date]
  end

  def parse_additional_info(year)
    add_info_array = []
    case_ids.each do |case_id|
      data_hash = {}
      data_hash[:court_id]          = COURT_ID
      data_hash[:case_id]           = case_id
      data_hash[:lower_case_id]     = get_lower_case_id
      data_hash[:lower_court_name]  = document[get_trial_index-2...get_trial_index].join(' ').squish
      data_hash[:lower_judge_name]  = document[get_trial_index + 1].squish
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash[:data_source_url]   = "https://www.la2nd.org/opinions/?opinion_year=#{year}"
      data_hash                     = mark_empty_as_nil(data_hash)
      add_info_array << data_hash
    end
    add_info_array
  end

  def parse_activities(pdf_link, opinion_date, year)
    activity_array = []
    case_ids.each do |case_id|
      data_hash = {}
      data_hash[:court_id]          = COURT_ID
      data_hash[:case_id]           = case_id
      data_hash[:file]              = pdf_link
      data_hash[:activity_date]     = get_date_format(opinion_date)
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:activity_type]     = 'Opinion'
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash[:data_source_url]   = "https://www.la2nd.org/opinions/?opinion_year=#{year}"
      data_hash                     = mark_empty_as_nil(data_hash)
      activity_array << data_hash
    end
    activity_md5_array = get_md5_array(activity_array)
    [activity_array,activity_md5_array]
  end

  def parse_case_pdf_aws(pdf_link)
    file_name = pdf_link.split('/').last
    case_pdf_array = []
    case_ids.each do |case_id|
      key = "us_courts_expansion/#{COURT_ID}/#{case_id}/#{file_name}"
      data_hash = {}
      data_hash[:court_id]          = COURT_ID
      data_hash[:case_id]           = case_id
      data_hash[:aws_link]          = key
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:source_type]       = 'activity'
      data_hash[:source_link]       = pdf_link
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash                     = mark_empty_as_nil(data_hash)
      case_pdf_array << data_hash
    end
    aws_md5_array = get_md5_array(case_pdf_array)
    [case_pdf_array,aws_md5_array]
  end

  def parse_relation_activity(activity_md5, aws_md5)
    relation_array = []
    case_ids.each_with_index do |case_id,index|
      data_hash = {}
      data_hash[:court_id]            = COURT_ID
      data_hash[:case_activities_md5] = activity_md5[index]
      data_hash[:case_pdf_on_aws_md5] = aws_md5[index]
      data_hash[:run_id]              = run_id
      data_hash[:touched_run_id]      = run_id
      data_hash                       = mark_empty_as_nil(data_hash)
      relation_array << data_hash
    end
    relation_array
  end

  def parse_parties(year, pdf_link)
    versus_index = get_versus_index
    parties_data = (versus_index.nil?) ? [] : get_parties_data(year,pdf_link)
    change_format_parties_data = get_change_format_parties_data(year,pdf_link)
    parties_data.concat(change_format_parties_data)
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  private

  attr_reader :document, :run_id ,:case_ids ,:t_head, :th_index, :reader

  def get_parties_data(year, pdf_link)
    data_array = []
    case_ids.each_with_index do |case_id,index|
      (0..1).each do |row|
        array = get_parties_array(row)
        data_hash = {}
        data_hash[:court_id]          = COURT_ID
        data_hash[:case_id]           = case_id
        data_hash[:is_lawyer]         = 0
        data_hash[:party_name]        = array.map{|e| e.split('  ').first}.join(' ')
        data_hash[:party_type]        = array.first.split('  ').last
        data_hash[:party_description] = array.join(' ').squish
        data_hash[:md5_hash]          = create_md5_hash(data_hash)
        data_hash[:pdf_link]          = pdf_link
        data_hash[:run_id]            = run_id
        data_hash[:touched_run_id]    = run_id
        data_hash[:data_source_url]   = "https://www.la2nd.org/opinions/?opinion_year=#{year}"
        data_hash                     = mark_empty_as_nil(data_hash)
        data_array << data_hash unless ((data_hash[:party_name].nil?) || (data_hash[:party_name].size > 500))
      end
    end
    data_array
  end

  def get_change_format_parties_data(year, pdf_link)
    data_array = []
    case_ids.each_with_index do |case_id,index|
      party_array = get_change_format_parties_array
      (0..1).each do |row|
        party_array.each do |array|
          data_hash = {}
          data_hash[:court_id]          = COURT_ID
          data_hash[:case_id]           = case_id
          data_hash[:is_lawyer]         = row
          data_hash[:party_type]        = get_party_type(array,row).gsub(',', '').strip rescue nil
          data_hash[:party_name]        = get_party_name(array,row,data_hash[:party_type])
          data_hash[:party_description] = array.join(' ').squish
          data_hash[:pdf_link]          = pdf_link
          data_hash[:md5_hash]          = create_md5_hash(data_hash)
          data_hash[:run_id]            = run_id
          data_hash[:touched_run_id]    = run_id
          data_hash[:data_source_url]   = "https://www.la2nd.org/opinions/?opinion_year=#{year}"
          data_hash                     = mark_empty_as_nil(data_hash)
          data_array << data_hash unless ((data_hash[:party_name].nil?) || (data_hash[:party_name].size > 500))
        end
      end
    end
    data_array
  end

  def get_party_name(array, row, party_type)
    if row == 0
      value = desc = array.select{|a| a.split("  ").count > 4}.map{|a| a.split("  ").last}.join(" ")
      handling_party_name_condition(value,party_type)
    else
      desc = array.select{|a| a.split("  ").select{|a| a.empty?}.count < 15}
      desc.map{|a| a.split("  ").reject{|e| e.empty?}.first}.join(" ").squish
    end
  end

  def handling_party_name_condition(value, party_type)
    use_cases = ['counsel for','pro se','in proper person']
    use_cases.each do |use_case|
      value = value.split(party_type.split('-').last).last.squish rescue nil
      return nil if (value.nil?) || (value.downcase == use_case)
    end
    value.split(party_type.split('-').last).last.gsub(',','').squish
  end

  def get_party_type(array, row)
    inner_array = array[0].split('  ')
    if inner_array.count > 1
      string = inner_array.last.strip
      if (string.last == '-') || (string.last == 'r')
        if check_inner_condition(string)
          if (row == 0)
            "#{string.split.last.strip} #{get_clean_value(array)}".gsub('for','')
          else
            "#{string} #{get_clean_value(array)}"
          end
        else
          "#{string} #{get_clean_value(array)}"
        end
      else
        if check_inner_condition(string)
          (row == 0) ? string.split.last.strip : string
        else
          string
        end
      end
    else
      nil
    end
  end

  def check_inner_condition(string)
    return true if (string.downcase.include? 'counsel')
    false
  end

  def get_clean_value(array)
    array[1].split('  ').last.split.first
  end

  def get_parties_array(row)
    versus_index = get_versus_index
    if (row == 0)
      list_1 = document[0..versus_index].reverse
      party_1_index = get_value_index(list_1,get_document_value(list_1,'*'))
      list_1[1...party_1_index].reverse
    else
      list_2 = document[versus_index..]
      party_2_index = get_value_index(list_2,get_document_value(list_2,'*'))
      list_2[1...party_2_index]
    end
  end

  def get_versus_index
    versus_value = get_document_value('versus')
    get_value_index(versus_value)
  end

  def get_change_format_parties_array
    all_parties_array = []
    start_index = get_trial_index + 3
    last_value = get_document_value('before')
    last_index = get_value_index(last_value) - 1
    array = document[start_index...last_index]
    first_cap = true
    party_array = []
    array.each_with_index do |line, index|
      first_cap = false unless check_upcase_condition(line)
      party_array << line
      next if first_cap
      if check_upcase_condition(line)
        first_cap = true
        all_parties_array << party_array[..-2]
        line = party_array.last
        party_array = []
        party_array << line
        next
      end
    end
    all_parties_array << party_array
    all_parties_array = handling_party_table_use_cases(all_parties_array)
  end

  def handling_party_table_use_cases(parties_array)
    temp_array = []
    parties_array.each do |array|
      flag = check_use_cases(array)
      if flag
        temp_array.append([array[0]])
        temp_array.append(array[1..])
      else
        temp_array.append(array)
      end
    end
    temp_array
  end

  def check_use_cases(array)
    use_cases = ['counsel','in proper']
    check_string = array[1].split('  ').last.downcase rescue []
    use_cases.each do |use_case|
      return true if (check_string.include? use_case)
    end
    false
  end

  def check_upcase_condition(line)(line)
    return true if (line.lstrip.split('  ').first.upcase == line.split('  ').first)
    false
  end

  def get_lower_case_id
    case_id_value = get_court_no_value
    case_id_value.split('.').last.strip
  end

  def get_date_format(opinion_date)
    DateTime.strptime(opinion_date,"%m/%d/%Y").to_date
  end

  def get_court_no_value
    keys = ['trial court no','trial court case no','lower court case no',
    'lower court no','trialcourt','docket no','lowercourt case no','triacourt']
    keys.each do |key|
      value = get_document_value(key)
      return value unless value.nil?
    end
  end

  def get_trial_index
    trial_value = get_court_no_value
    get_value_index(trial_value)
  end

  def get_value_index(page = document, key)
    page.index(key)
  end

  def get_document_value(doc = document, key)
    if (key.include? 'no') || (key == 'trialcourt')
      doc = reader.pages[0..1].map{|page| page.text.scan(/^.+/)}
      doc.flatten.select{|e| e.downcase.include? key}.first
    else
      doc.select{|e| e.downcase.include? key}.first
    end
  end

  def get_info_value(row, key)
    value_index = get_value_index(t_head,key)
    row.css('td')[value_index].text.squish
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def get_md5_array(data_array)
    data_array.map{|data_hash| data_hash[:md5_hash]}
  end

end
