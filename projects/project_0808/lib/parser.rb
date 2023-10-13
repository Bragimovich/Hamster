# frozen_string_literal: true

class Parser < Hamster::Parser
  SOURCE_URL = "https://docpub.state.or.us/OOS/searchCriteria.jsf"
  AWS_PREFIX = "https://hamster-storage1.s3.amazonaws.com"

  def parse_html(body)
    Nokogiri::HTML(body)
  end

  def get_view_states(page)
    page.css("input")[-2]["value"]
  end

  def get_match_result(page)
    matching_flag = false
    msg = page.css(".infoMessage").text.strip
    matching_flag = true if msg
    if msg.include?("Too many results to display. Be more specific.") or msg.include?("No matching records found.")
      [matching_flag, msg]
    end
  end

  def check_for_more_offenders(page)
    more_offender_flag = false
    num_of_pages = page.css("#mainBodyForm\\:pageMsg").text.split("/").last.to_i
    more_offender_flag = num_of_pages > 1 ? true : false
    [more_offender_flag, num_of_pages]
  end

  def get_offenders(page)
    offender_id_array = []
    all_rows = page.css("table.foundOffenders tbody tr")
    all_rows.each do |row|
      data_hash = {}
      table_cols = row.css("td")
      anchor = table_cols[0].css("a")
      offender_id = anchor.first["onclick"].scan(/mainBodyForm:foundOffenders:\d+:j_id\d+/).flatten.first
      data_hash["j_id"] = offender_id
      data_hash["sid_num"] = anchor.text
      offender_id_array.push(data_hash)
    end
    offender_id_array
  end

  def get_offender_data(parsed_page)
    data_hash = {}
    inmates_info_array = get_inmates_info(parsed_page)
    inmates_ids_array = get_inmates_ids(parsed_page)
    inmates_mugshots_array = get_inmates_mugshots(parsed_page)
    inmates_additional_info_array = get_inmates_additional_info(parsed_page)
    inmates_status_array = get_inmates_status(parsed_page)
    inmates_aliases_array = get_inmates_aliases(parsed_page)
    inmates_arrest_array = get_inmates_arrest(parsed_page)
    inmates_charges_array = get_inmates_charges(parsed_page)
    data_hash = {
      "inmates_info" => inmates_info_array,
      "inmates_ids" => inmates_ids_array,
      "inmates_mugshots" => inmates_mugshots_array,
      "inmates_additional_info" => inmates_additional_info_array,
      "inmates_status" => inmates_status_array,
      "inmates_aliases" => inmates_aliases_array,
      "inmates_arrest" => inmates_arrest_array,
      "inmates_charges" => inmates_charges_array,
    }
  end

  private 

  def get_inmates_info(page)
    data_array = []
    data_hash = {}
    full_name, first_name, last_name, middle_name, dob, gender, race = get_inmates_parsed_info(page)
    data_hash["full_name"] = full_name
    data_hash["first_name"] = first_name
    data_hash["middle_name"] = middle_name
    data_hash["last_name"] = last_name
    data_hash["birthdate"] = dob
    data_hash["sex"] = gender
    data_hash["race"] = race
    data_hash["suffix"] = ""
    data_hash["date_of_death"] = ""
    data_hash["data_source_url"] = SOURCE_URL
    data_hash = mark_empty_as_nil(data_hash)
    data_array.push(data_hash)
    data_array
  end

  def get_inmates_parsed_info(page)
    full_name = page.css("#offensesForm\\:publicInfoDetailName #offensesForm\\:name").text.strip
    name_parts = full_name.split(",")
    last_name = name_parts.first
    name_parts = name_parts.last.split(" ")
    middle_name = name_parts.last
    first_name = full_name.gsub(middle_name,"").gsub(last_name,"").gsub(",","").strip
    details = page.css("#offensesForm\\:publicInfoDetail")
    dob = Date.strptime(details.css("#offensesForm\\:dob").text.strip, "%m/%Y")
    dob = dob.strftime("%Y-%m")
    gender = details.css("#offensesForm\\:sex").text.strip
    race = details.css("#offensesForm\\:race").text.strip
    [full_name, first_name, last_name, middle_name, dob, gender, race]
  end

  def get_inmates_ids(page)
    data_array = []
    data_hash = {}
    sid_num = page.css("#offensesForm\\:photo_sid #offensesForm\\:out_SID").text.strip
    data_hash["number"] = sid_num
    data_hash["type"] = "SID (State Identification Number)"
    data_hash["data_source_url"] = SOURCE_URL
    data_hash = mark_empty_as_nil(data_hash)
    data_array.push(data_hash)
    data_array
  end

  def get_inmates_mugshots(page)
    data_array = []
    data_hash = {}
    org_link = page.css("#offensesForm\\:photo_sid .photo").first["src"].strip
    original_link = "https://docpub.state.or.us#{org_link}"
    file_name = org_link.split("idno=").last
    aws_link = "#{AWS_PREFIX}/inmates/or/task_808/#{file_name}.jpg"
    data_hash["aws_link"] = aws_link
    data_hash["original_link"] = original_link
    data_hash["notes"] = ""
    data_hash["data_source_url"] = SOURCE_URL
    data_hash = mark_empty_as_nil(data_hash)
    data_array.push(data_hash)
    data_array
  end

  def get_inmates_additional_info(page)
    data_array = []
    data_hash = {}
    height, weight, hair_color, eye_color, age, current_location = get_inmates_parsed_add_info(page)
    data_hash["height"] = height
    data_hash["weight"] = weight
    data_hash["hair_color"] = hair_color
    data_hash["eye_color"] = eye_color
    data_hash["age"] = age
    data_hash["current_location"] = current_location
    data_hash = mark_empty_as_nil(data_hash)
    data_array.push(data_hash)
    data_array
  end

  def get_inmates_parsed_add_info(page)
    details = page.css("#offensesForm\\:publicInfoDetail")
    height = details.css("#offensesForm\\:height").text.gsub("''","'").strip
    weight = details.css("#offensesForm\\:weight").text.strip
    hair_color = details.css("#offensesForm\\:hair").text.strip
    eye_color = details.css("#offensesForm\\:eyes").text.strip
    age = details.css("#offensesForm\\:age").text.strip
    current_location = details.css("a").text.strip
    [height, weight, hair_color, eye_color, age, current_location]
  end

  def get_inmates_status(page)
    data_array = []
    data_hash = {}
    status, date_of_status_change, notes = get_inmates_parsed_statuses(page)
    data_hash["status"] = status
    data_hash["date_of_status_change"] = date_of_status_change
    data_hash["notes"] = notes
    data_hash["data_source_url"] = SOURCE_URL
    data_hash = mark_empty_as_nil(data_hash)
    data_array.push(data_hash)
    data_array
  end

  def get_inmates_parsed_statuses(page)
    details = page.css("#offensesForm\\:publicInfoDetail")
    status = details.css("#offensesForm\\:status").text.strip
    date_of_status_change = ""
    notes = "A status of 'Inmate' indicates that the offender is currently incarcerated in a state institution, while other status indicates the state of supervision by a county parole/probation office"
    [status, date_of_status_change, notes]
  end

  def get_inmates_aliases(page)
    data_array = []
    alias_table_rows  = page.css("#offensesForm\\:namesTable tbody tr")
    alias_table_rows.each do |row|
      full_name, first_name, middle_name, last_name, suffix, key, value = get_inmates_parsed_aliases(row, page)
      data_hash = {}
      data_hash["full_name"] = full_name
      data_hash["first_name"] = first_name
      data_hash["middle_name"] = middle_name
      data_hash["last_name"] = last_name
      data_hash["suffix"] = suffix
      data_hash["key"] = key
      data_hash["value"] = value
      data_hash["data_source_url"] = SOURCE_URL
      data_hash = mark_empty_as_nil(data_hash)
      data_array.push(data_hash)
    end   
    data_array
  end

  def get_inmates_parsed_aliases(row, page)
    row = row.css("td")
    last_name = row[0].text.strip
    first_name = row[1].text.strip
    middle_name = row[2].text.strip
    full_name = "#{last_name} #{first_name} #{middle_name}"
    suffix = ""
    key = "Type"
    value = row[3].text.strip 
    [full_name, first_name, middle_name, last_name, suffix, key, value]
  end

  def get_inmates_arrest(page)
    data_array = []
    data_hash = {}
    status, officer, booking_date, booking_number = get_inmates_parsed_arrest(page)
    data_hash["status"] = status
    data_hash["officer"] = officer
    data_hash["booking_date"] = booking_date
    data_hash["booking_number"] = booking_number
    data_hash["data_source_url"] = SOURCE_URL
    data_hash = mark_empty_as_nil(data_hash)
    data_array.push(data_hash)
    data_array
  end

  def get_inmates_parsed_arrest(page)
    status = ""
    officer = ""
    booking_date = ""
    booking_number = ""
    [status, officer, booking_date, booking_number]
  end

  def get_inmates_charges(page)
    data_array = []
    charge_table_rows  = page.css("#offensesForm\\:offensesTable tbody tr")
    charge_table_rows.each do |row|
      row = row.css("td")
      next if  row[0].text.strip.empty?
      charge_number, charge_disposition, charge_disposition_date, charge_description, charge_offense_type, charge_offense_date, charge_offense_time, docket_number, charge_crime_class, additional_key, additional_value, hearing_sentence_type, hearing_case_number, hearing_case_type, hearing_min_release_date, hearing_max_release_date, holding_start_date, holding_planned_release_date, holding_actual_release_date, holding_max_release_date, holding_total_time  = get_inmates_parsed_charges(row)
      data_hash = {}
      data_hash["number"] = charge_number
      data_hash["disposition"] = charge_disposition
      data_hash["disposition_date"] = charge_disposition_date
      data_hash["description"] = charge_description
      data_hash["offense_type"] = charge_offense_type
      data_hash["offense_date"] = charge_offense_date
      data_hash["offense_time"] = charge_offense_time
      data_hash["crime_class"] = charge_crime_class
      data_hash["key"] = additional_key
      data_hash["value"] = additional_value
      data_hash["sentence_type"] = hearing_sentence_type
      data_hash["case_number"] = hearing_case_number
      data_hash["case_type"] = hearing_case_type
      data_hash["min_release_date"] = hearing_min_release_date
      data_hash["max_release_date"] = hearing_max_release_date
      data_hash["start_date"] = holding_start_date
      data_hash["planned_release_date"] = holding_planned_release_date
      data_hash["actual_release_date"] = holding_actual_release_date
      data_hash["max_release_date"] = holding_max_release_date
      data_hash["total_time"] = holding_total_time
      data_hash["docket_number"] = docket_number
      data_hash["data_source_url"] = SOURCE_URL
      data_hash = mark_empty_as_nil(data_hash)
      data_array.push(data_hash)
    end   
    data_array
  end

  def get_inmates_parsed_charges(row)
    charge_number = ""
    charge_disposition = ""
    charge_disposition_date = ""
    charge_description = ""
    charge_offense_type = row[2].text.strip
    charge_offense_date = ""
    charge_offense_time = ""
    charge_crime_class = ""
    docket_number = row[0].text.strip
    additional_key = "County"
    additional_value = row[1].text.strip
    hearing_sentence_type = row[3].text.strip
    hearing_case_number = ""
    hearing_case_type = ""
    hearing_min_release_date = ""
    hearing_max_release_date = ""
    holding_start_date = row[4].text.strip
    holding_start_date = Date.strptime(holding_start_date, "%m/%d/%Y").to_s unless holding_start_date.empty?
    holding_planned_release_date = row[5].text.strip
    holding_planned_release_date = Date.strptime(holding_planned_release_date, "%m/%d/%Y").to_s unless holding_planned_release_date == "-" or holding_planned_release_date.empty?
    holding_actual_release_date = ""
    holding_max_release_date = ""
    holding_total_time = ""
    [charge_number, charge_disposition, charge_disposition_date, charge_description, charge_offense_type, charge_offense_date, charge_offense_time, docket_number, charge_crime_class, additional_key, additional_value, hearing_sentence_type, hearing_case_number, hearing_case_type, hearing_min_release_date, hearing_max_release_date, holding_start_date, holding_planned_release_date, holding_actual_release_date, holding_max_release_date, holding_total_time ]
  end
 
  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end
  
end
