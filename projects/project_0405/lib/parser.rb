# frozen_string_literal: true
class Parser < Hamster::Parser

  def get_inner_links(outer_page)
    outer_page = Nokogiri::HTML(outer_page.force_encoding("utf-8"))
    outer_page.css('table.FormTable td a').map{|a| a['href']}.reject {|l| l.exclude? "/public" }
  end

  def get_inner_data(page, run_id)
    page       = Nokogiri::HTML(page.force_encoding("utf-8"))
    page_id    = page.css("#caseViewForm input[name='csIID']")[0]["value"] rescue nil
    return [] if page_id.nil?
    url        = "https://efile.dcappeals.gov/public/caseView.do?csIID=#{page_id}"
    case_id    = page.css("#content-container table.FormTable tr")[0].text
    case_id    = case_id.split(":")
    case_id    = case_id[1].squish
    case_info  = case_info(page, case_id, url, run_id)
    case_consolidations  = case_consolidations(page, case_id, url, run_id)
    case_additional_info = case_additional_info(page, case_id, url, run_id)
    us_case_party        = us_case_party(page, case_id, url, run_id)
    us_case_activities   = us_case_activities(page, case_id, url, run_id)
    [case_info, case_consolidations, case_additional_info, us_case_party, us_case_activities]
  end

  def get_values(page, search_text)
    values = page.css("td.label").select{|e| e.text.include? "#{search_text}"}
    unless values.empty?
      value = values[0].next_element.text.strip
    else
      value = nil
    end
  end

  def fetch_pdf_names(html)
    body = Nokogiri::HTML(html.force_encoding("utf-8"))
    body.css("img").select{|l| l['class'] =="documentLink"}.map{|l| l['name']}
  end

  def case_info(page, case_id, url, run_id)
    data_hash = {}
    data_hash[:court_id]              = 57
    data_hash[:case_id]               = case_id
    data_hash[:case_name]             = get_values(page, "Short Caption:")
    data_hash[:case_filed_date]       = DateTime.strptime(get_values(page, "Filed Date:"), "%m/%d/%Y").to_date rescue nil
    data_hash[:case_type]             = get_values(page, "Classification:")
    data_hash[:status_as_of_date]     = get_values(page, "Case Status:")
    data_hash[:disposition_or_status] = get_values(page, "Disposition:")
    data_hash[:data_source_url]       = url
    data_hash[:lower_court_id]        = 1003
    data_hash[:lower_case_id]         = get_values(page, "Superior Court or Agency Case Number:")
    data_hash[:md5_hash]              = create_md5_hash(data_hash)
    data_hash                         = mark_empty_as_nil(data_hash)
    data_hash[:run_id]                = run_id
    data_hash
  end

  def case_consolidations(page, case_id, url, run_id)
    consolidations_hash_array = []
    consolidate_value = get_values(page, "Lead:")
    consolidated_case_id = get_values(page, "Consolidated:")
    consolidated_case_id = consolidated_case_id.split(",") rescue nil
    consolidated_case_id.append(consolidate_value) unless consolidate_value.nil?
    return consolidations_hash_array if consolidated_case_id.nil?
    consolidated_case_id = consolidated_case_id.reject {|c| c.include? case_id }
    consolidated_case_id.each do |consolidate|
      dc_ac_case_consolidations = {}
      dc_ac_case_consolidations[:court_id]             = 57
      dc_ac_case_consolidations[:case_id]              = case_id
      dc_ac_case_consolidations[:consolidated_case_id] = consolidate
      dc_ac_case_consolidations[:data_source_url]      = url
      dc_ac_case_consolidations[:md5_hash]             = create_md5_hash(dc_ac_case_consolidations)
      dc_ac_case_consolidations                        = mark_empty_as_nil(dc_ac_case_consolidations)
      dc_ac_case_consolidations[:run_id]               = run_id
      consolidations_hash_array.append(dc_ac_case_consolidations)
    end
    consolidations_hash_array
  end

  def case_additional_info(page, case_id, url, run_id)
    dc_ac_case_additional_info = {}
    dc_ac_case_additional_info[:court_id]        = 57
    dc_ac_case_additional_info[:case_id]         = case_id
    dc_ac_case_additional_info[:lower_case_id]   = get_values(page, "Superior Court or Agency Case Number:")
    return nil if dc_ac_case_additional_info[:lower_case_id].empty?
    dc_ac_case_additional_info[:data_source_url] = url
    dc_ac_case_additional_info[:md5_hash]        = create_md5_hash(dc_ac_case_additional_info)
    dc_ac_case_additional_info                   = mark_empty_as_nil(dc_ac_case_additional_info)
    dc_ac_case_additional_info[:run_id]          = run_id
    dc_ac_case_additional_info
  end

  def us_case_party(page, case_id, url, run_id)
    party_hash_array = []
    all_parties = page.css("#partyInfo tr")[2..-1].reject{|e| e.css("td").count <= 3} rescue nil
    return party_hash_array if all_parties.nil? or all_parties.empty?
    all_parties.each do |party|
      lawyers = []
      lawyers = party.css("td")[3].css("tr").count > 0 ? party.css("td")[3].css("tr").map{|l| l.css("td")[0].text} : lawyers.append(party.css("td")[3].text)
      lawyers = lawyers.append(party.css("td")[1].text).reject { |e| e.squish.empty? }
      lawyers.each do |lawyer|
        data_hash = {}
        data_hash[:court_id]        = 57
        data_hash[:case_id]         = case_id
        data_hash[:is_lawyer]       = (0 if lawyer == lawyers.last) || 1
        data_hash[:party_name]      = lawyer
        data_hash[:party_type]      = party.css("td")[0].text.squish
        data_hash[:data_source_url] = url
        data_hash[:md5_hash]        = create_md5_hash(data_hash)
        data_hash                   = mark_empty_as_nil(data_hash)
        data_hash[:run_id]          = run_id
        party_hash_array << data_hash
      end
    end
    party_hash_array.uniq
  end

  def us_case_activities(page, case_id, url, run_id)
    activities_hash_array = []
    all_events = page.css("table.FormTable")[-1].css("tr")[2..-1]
    all_events.each do |event|
      data_hash = {}
      data_hash[:court_id]        = 57
      data_hash[:case_id]         = case_id
      data_hash[:activity_date]   = DateTime.strptime(event.css("td")[0].text, "%m/%d/%Y").to_date rescue nil
      data_hash[:activity_desc]   = event.css("td")[2].text
      data_hash[:data_source_url] = url
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash                   = mark_empty_as_nil(data_hash)
      data_hash[:run_id]          = run_id
      activities_hash_array << data_hash
    end
    activities_hash_array
  end

  def activities_pdfs_on_aws(pdf_url_link, case_info, type, pdf_name)
    data_hash_pdf = {}
    data_hash_pdf[:court_id]        = case_info[:court_id]
    data_hash_pdf[:case_id]         = case_info[:case_id]
    data_hash_pdf[:source_type]     = type
    data_hash_pdf[:aws_html_link]   = data_hash_pdf[:aws_link] = nil
    if type == "info"
      data_hash_pdf[:aws_html_link] = "us_courts_expansion_#{data_hash_pdf[:court_id].to_s}_#{data_hash_pdf[:case_id].to_s}_#{pdf_name}"
    else
      data_hash_pdf[:aws_link]      = "us_courts_expansion_#{data_hash_pdf[:court_id].to_s}_#{data_hash_pdf[:case_id].to_s}_#{type.to_s}_#{pdf_name}.pdf"
    end
    data_hash_pdf[:source_link]     = pdf_url_link
    data_hash_pdf[:md5_hash]        = create_md5_hash(data_hash_pdf)
    data_hash_pdf                   = mark_empty_as_nil(data_hash_pdf)
    data_hash_pdf[:run_id]          = case_info[:run_id]
    data_hash_pdf
  end

  def case_relations_activity_pdf(pdf_md5, activity_pdf)
    case_relations_activity = {}
    case_relations_activity[:case_activities_md5] = activity_pdf
    case_relations_activity[:case_pdf_on_aws_md5] = pdf_md5
    case_relations_activity
  end

  def case_relations_info_pdf(pdf_md5, activity_pdf)
    case_relations_activity = {}
    case_relations_activity[:case_info_md5] = activity_pdf
    case_relations_activity[:case_pdf_on_aws_md5] = pdf_md5
    case_relations_activity
  end

  def find_activity_index(html, start_name)
    value      = nil
    start_name = start_name.split("_").join(":")
    body       = Nokogiri::HTML(html.force_encoding("utf-8"))
    all_events = body.css("table.FormTable")[-1].css("tr")[2..-1]
    all_events.each_with_index do |event, index|
      unless event.css("img").empty?
        value = (event.css("img")[0]['name'].end_with? start_name) ? index : nil
      end
      break unless value.nil?
    end
    value
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? or value == 'NULL') ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
