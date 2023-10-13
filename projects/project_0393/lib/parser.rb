# frozen_string_literal: true
class Parser <  Hamster::Scraper
  
  COURT_ID = 12

  def get_inner_links(response)
    data = Nokogiri::HTML(response.force_encoding("utf-8"))
    data.css("table tr")[1..-1].map{|e| e.css("td")[-2].css("a")[0]["href"]}.reject{|l| l == nil}
  end

  def parse(file_content, link, run_id)
    @doc = Nokogiri::HTML(file_content.force_encoding("utf-8"))
    @all_activities = []
    all_rows = @doc.css("#main-content table")[2].css("tr")
    html = @doc.css("#main-content")
    info_data_hash,info_md5 = get_case_info_details(html, link, run_id)
    court_actions(html,info_data_hash,run_id)
    parties_data_array = get_attorney_details(html, info_data_hash, run_id)
    additional_info_hash = get_trail_court_details(html, info_data_hash, run_id)
    activities_descriptions , activities_date = get_activities_details(all_rows)
    get_data_case_activity(activities_descriptions, activities_date, info_data_hash, run_id)
    aws_data_hash = case_pdfs_on_aws(html, info_data_hash, run_id) # need to implement
    aws_info_relation_hash = case_relations_info_pdf(info_md5, aws_data_hash[:md5_hash])
    [info_data_hash, additional_info_hash, parties_data_array, @all_activities, aws_data_hash, aws_info_relation_hash]    
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end

  def table_heading_method(html, word_match)
    return_variable = nil
    column_value = html.css("h3").select{|e| e.text.downcase.include?(word_match.downcase)} rescue nil
    if column_value
      return_variable = (word_match == "Court of Appeals Information" || word_match == "Trial Court Information" || word_match == "Court Initiated Actions") ? column_value[0].next_element : column_value[0].next_element.next_element rescue nil
    end
    return_variable
  end

  def court_actions(html, info_data_hash, run_id)
    actions = table_heading_method(html, "Court Initiated Actions")
    return if actions.nil? || actions.css("td")[0].text == "None"
    while(actions.name=="table")
      data_hash={}
      data_hash[:case_id] = info_data_hash[:case_id]
      data_hash[:activity_date] = actions.css("td")[0].text
      data_hash[:activity_type] = actions.css("td")[1].text
      data_hash[:court_id] = COURT_ID
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = info_data_hash[:data_source_url]
      data_hash[:run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      @all_activities << data_hash
      actions = actions.next_element
    end
  end

  def get_trail_court_details(html, info_data_hash, run_id)
    table = table_heading_method(html, "Trial Court Information")
    lower_case_id = table_row_method(table,"Case Number")
    judge_name = table_row_method(table, "Judge").squish
    lower_judgement_date = Date.parse(table_row_method(table,"Appealed Order").squish).to_date rescue nil
    lower_court_name = table_row_method(table,"Clerk").gsub("Clerk","").gsub("County","").squish
    data_hash = {}
    data_hash[:lower_court_name] = lower_court_name
    data_hash[:lower_judge_name] = judge_name
    data_hash[:lower_case_id] = lower_case_id
    data_hash[:lower_judgement_date] = lower_judgement_date
    data_hash[:court_id] = COURT_ID
    data_hash[:case_id] = info_data_hash[:case_id]
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = info_data_hash[:data_source_url]
    data_hash[:run_id] = run_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end

  def get_trail_lower_case(html)
    table = table_heading_method(html, "Trial Court Information")
    lower_case_id = table_row_method(table,"Case Number")
    lower_case_id
  end

  def get_case_info_details(html, link, run_id)
    table = table_heading_method(html, "Court of Appeals Information")
    case_number  = table_row_method(table, "Case Number")  
    case_name  = table_row_method(table, "Style").squish
    case_filed_date  = Date.parse(table_row_method(table, "Docket/Notice Date").squish).to_date rescue nil 
    disposition_or_status = table_row_method(table, "COA Judgment/Ruling") rescue nil
    status_as_of_date = table_row_method(table, "Status").squish
    data_hash = {}
    data_hash[:case_name] = case_name.squish
    data_hash[:case_id] = case_number
    data_hash[:case_filed_date] = case_filed_date
    data_hash[:disposition_or_status] = disposition_or_status
    data_hash[:status_as_of_date] = status_as_of_date
    data_hash[:court_id] = COURT_ID
    data_hash[:lower_case_id] = get_trail_lower_case(html)
    info_md5 = create_md5_hash(data_hash)
    data_hash[:data_source_url] = link
    data_hash[:run_id] = run_id
    data_hash = mark_empty_as_nil(data_hash)
    [data_hash,info_md5]
  end

  def get_parties_data_hash(party_array, party_type, info_data_hash, run_id)
    all_parties = []
    party_array.each do |party_name|
      data_hash = {}
      data_hash[:case_id] = info_data_hash[:case_id]
      data_hash[:party_name] = party_name
      data_hash[:party_type] = party_type
      data_hash[:is_lawyer] = 1
      data_hash[:court_id] = COURT_ID
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = info_data_hash[:data_source_url]
      data_hash[:run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      all_parties << data_hash
    end
    all_parties
  end

  def get_attorney_details(html, info_data_hash, run_id)
    list_appellant = []
    list_appelle = []
    parties_data_array = []
    list_appellant = html.css("table").select{|e|  e.text.include?("Appellant")}[0].css("td").map{|e| e.text} rescue []
    list_appelle = html.css("table").select{|e|  e.text.include?("Appellee")}[0].css("td").map{|e| e.text} rescue []
    parties_data_array = get_parties_data_hash(list_appellant, "Appellant", info_data_hash, run_id)
    parties_data_array << get_parties_data_hash(list_appelle, "Appellee", info_data_hash, run_id)
    parties_data_array.flatten  
  end

  def get_data_case_activity(activities_descriptions,activities_date, info_data_hash, run_id)
    activities_descriptions.each_with_index do |value, index_no|
      data_hash={}
      data_hash[:case_id] = info_data_hash[:case_id]
      data_hash[:activity_date] = activities_date[index_no]
      data_hash[:activity_type] = value
      data_hash[:court_id] = COURT_ID
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = info_data_hash[:data_source_url]
      data_hash[:run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      @all_activities << data_hash
    end
  end
  
  def get_activities_details(all_rows)
    activities_descriptions =[]
    activities_date =[]
    for i in 0...all_rows.count
      if all_rows[i].css("td").first.text == "Filing" or all_rows[i].css("td").first.text == "Motion" or all_rows[i].css("td").first.text == "Court Action"
        activities_descriptions << all_rows[i].css("td").last.text
      elsif all_rows[i].css("td").first.text == "Filing Date" or all_rows[i].css("td").first.text == "Motion Date" or all_rows[i].css("td").first.text == "Court Action Date"
        activities_date << Date.parse(all_rows[i].css("td").last.text).to_date
      end
    end
    [activities_descriptions, activities_date]
  end
  
  def table_row_method(table, word_match)
    return_variable = nil
    if word_match == "Opinion/Order"
      column_value    = table.css("td").select{|e| e.text.downcase.include?(word_match.downcase)}
      return_variable = column_value[0].next_element.css("a")[0]['href'] if column_value.count > 0 && column_value[0].next_element.css("a").count > 0
    else 
      column_value = table.css("th").select{|e| e.text.downcase.include?(word_match.downcase)} rescue nil
      return_variable = column_value[0].next_element.text if column_value rescue nil
    end
    return_variable
  end

  def case_pdfs_on_aws(html, info_data_hash, run_id)
    data_hash = {}
    file = table_row_method(html, "Opinion/Order")
    return {} if file.nil?
    data_hash[:court_id] = COURT_ID
    data_hash[:case_id] = info_data_hash[:case_id]
    data_hash[:source_type] = 'info'
    file_name = file.split('-').last
    key = 'us_courts_expansion_' + COURT_ID.to_s + '_' +info_data_hash[:case_id].to_s + '_' + file_name + '.pdf'
    data_hash[:aws_link] = key
    data_hash[:source_link] = file
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = info_data_hash[:data_source_url]
    data_hash[:run_id] = run_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end

  def case_relations_info_pdf(info_md5_hash, aws_md5_hash)
    data_hash = {}
    data_hash[:court_id] = COURT_ID
    data_hash[:case_info_md5] = info_md5_hash
    data_hash[:case_pdf_on_aws_md5] = aws_md5_hash
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end
  
  def create_md5_hash(data_hash)
    data_hash[:case_name] = data_hash[:case_name].upcase if (data_hash.include? :case_name)
    data_hash[:party_name] = data_hash[:party_name].upcase if (data_hash.include? :party_name)
    Digest::MD5.hexdigest data_hash.values * ""
  end
  
end
