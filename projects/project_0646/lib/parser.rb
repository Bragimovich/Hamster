# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_data(case_body,party_body,docket_body,run_id)
    @run_id = run_id
    case_info = parse_case_info(case_body)
    party_info = parse_party_info(party_body)
    activity_info = parse_activity_info(docket_body)
    [case_info,party_info,activity_info]
  end

  def get_case_ids(response)
    page = parse_page_html(response.body)
    page.css("table[cellspacing = '2'] a").map{|e| e.text.squish}
  end

  private

  def parse_case_info(case_body)
    case_page = parse_page(case_body)
    @case_id = case_page['caseNumber']
    case_info_array = []
    data_hash = {}
    filed_date = case_page['filingDate']
    disposition_date = case_page['caseDispositionDetail']['docketFilingDate']
    data_hash[:case_id] = @case_id
    data_hash[:case_name] = case_page['caseDesc']
    data_hash[:case_filed_date] = get_date_format(filed_date)
    data_hash[:case_type] = case_page['caseType']
    data_hash[:status_as_of_date] = case_page['caseDispositionDetail']['dispositionDescription']
    data_hash[:disposition_or_status] = get_date_format(disposition_date)
    data_hash[:judge_name] =  case_page['judgeDetails']['formattedName'] rescue nil
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = @run_id
    data_hash[:touched_run_id] = @run_id
    data_hash = mark_empty_as_nil(data_hash)
    case_info_array << data_hash
  end

  def parse_activity_info(docket_body)
    docket_page = parse_page(docket_body)
    docket_array = []
    activity_rows = docket_page['docketTabModelList']
    return [] if (activity_rows.nil?)
    activity_rows.each do |row|
      activity_desc = get_activity_desc(row)
      date = row['filingDate']
      data_hash = {}
      data_hash[:case_id] = @case_id
      data_hash[:activity_date] = get_date_format(date)
      data_hash[:activity_type] = row['docketDesc']
      data_hash[:activity_decs] = activity_desc
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = @run_id
      data_hash[:touched_run_id] = @run_id
      data_hash = mark_empty_as_nil(data_hash)
      docket_array << data_hash
    end
    docket_array
  end

  def get_activity_desc(row)
    if ((row['filingPartyFullName'] != "") && (row['behalfOfPartiesNames'] != ""))
      activity_desc = "#{row['docketText']} Filed By: #{row['filingPartyFullName']} On Behalf Of: #{row['behalfOfPartiesNames']}"
    elsif ((row['filingPartyFullName'].empty?) && (row['behalfOfPartiesNames'] != ""))
      activity_desc = "#{row['docketText']} On Behalf Of: #{row['behalfOfPartiesNames']}"
    elsif ((row['behalfOfPartiesNames'].empty?) && (row['filingPartyFullName'] != ""))
      activity_desc = "#{row['docketText']} Filed By: #{row['filingPartyFullName']}"
    else
      activity_desc = "#{row['docketText']}"
    end
    replace_sequence(activity_desc).squish
  end

  def parse_party_info(party_body)
    party_page = parse_page(party_body)
    party_list = party_page['partyDetailsList']
    lawyer_list = party_page['partyDetailsList'].map{|e| e['attorneyList']}.reject{|e| e.empty?}.flatten
    co_lawyer_list = lawyer_list.map{|e| e['coAttorneyList']}.reject{|e| e.empty?}.flatten
    lawyer_0_list = get_party_info(party_list,0)
    lawyer_1_list = get_party_info(lawyer_list.concat(co_lawyer_list),1)
    lawyer_0_list.concat(lawyer_1_list)
  end

  def get_party_info(party_list,is_lawyer)
    data_array = []
    party_list.each do |party|
      data_hash = {}
      data_hash[:case_id] = @case_id
      data_hash[:is_lawyer] = is_lawyer
      data_hash[:party_name] = party['formattedPartyName']
      data_hash[:party_type] = party['desc']
      data_hash[:party_description] = "#{party['formattedPartyAddress']} #{party['formattedTelePhone']} #{party['birthDate']}".squish
      data_hash[:party_address] = party['formattedPartyAddress'].to_s.squish
      data_hash[:party_city] = party['addrCity']
      data_hash[:party_state] = party['addrStatCode']
      data_hash[:party_zip] = party['addrZip']
      data_hash[:run_id] = @run_id
      data_hash[:touched_run_id] = @run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def replace_sequence(string)
    modified_string = string.dup.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').squish
    modified_string
  end

  def parse_page(response)
    JSON.parse(response)
  end

  def get_date_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : replace_sequence(value.to_s).squish}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def parse_page_html(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

end
