require_relative '../models/all_states'
require_relative '../models/all_cities'
class Parser

  BASE_URL = "https://www.courts.wa.gov"

  def initialize
    @all_states = AllStates.pluck(:short_name).uniq
    @all_cities = AllCities.pluck(:short_name).uniq
  end

  def get_all_links(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//*[@class='medium']"
    parsed_page.xpath(xpath)
  end

  def get_links(pdf_div)
    row = pdf_div.parent.parent
    row_data = row.children.select{|x| x.element? }
    if row_data.length == 1
      row_which_include_links = row_data[0].children.select{|x|x.element?}
    else
      row_which_include_links = row_data[1].children.select{|x|x.element?}
    end
    inner_page_link = BASE_URL + row_which_include_links[0]['href']
    if row_which_include_links[1]['href'].include?("www.courts.wa.gov")
      pdf_link = row_which_include_links[1]['href'].gsub(/http:/,'https:')
    else
      pdf_link = BASE_URL + row_which_include_links[1]['href']
    end
    pdf_link = pdf_link.gsub(" ","%20")
    [inner_page_link,pdf_link]
  end
  
  def parse_rows(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    all_href_tags = parsed_page.xpath("//a")
    # filter all hrefs with href with pdf endpoint in them
    all_href_tags.select{|x| x['href']&.include?("/pdf/") }
  end

  def parse_inner_page(file_content ,data_source_url)
    parsed_page = Nokogiri::HTML(file_content)
    all_table_xpath = "//table//table"
    all_tables = parsed_page.xpath(all_table_xpath)

    all_tables.each do |table|
      title = table.previous_sibling.previous_sibling&.text
      if title&.include?("Opinion Information Sheet")
        @case_info = parse_opinon_information_sheet_table(table)
      elsif title&.include?("SOURCE OF APPEAL")
        @addition_info = parse_source_of_appeal_table(table)
      elsif title&.include?("JUSTICES")
        @judges_names = parse_justices_table(table)
      elsif title&.include?("COUNSEL OF RECORD")
        @list_of_parties = parse_counsel_of_record_table(table)
      end
    end
    court_id = get_court_id(all_tables[0]&.previous_sibling&.previous_sibling&.text)
    case_id = @case_info["case_id"]    
    @addition_info['court_id'] = court_id
    @addition_info['case_id'] = case_id  
    
    @case_info['judge_name'] = @judges_names
    @case_info['court_id'] = court_id
    @case_info['lower_case_id'] = @addition_info['lower_case_id']
    @case_info['data_source_url'] = data_source_url
    @case_info['status_as_of_date'] = 'Active'


    @list_of_parties.each do |party|
      party['court_id'] = court_id
      party['case_id'] = case_id
      party['data_source_url'] = data_source_url
    end
    
    {
      case_info: @case_info,
      additional_info: @addition_info,
      list_of_parties: @list_of_parties
    }
  end


  def get_case_filed_date(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@class='dw-search-result std-vertical-med-margin']/div[@class='dw-search-result-right']"
    match = parsed_page.xpath(xpath)&.first
    if match.present?
      xpath = "div[@class='dw-icon-row']/div[2]/span[2]"
      case_file_date = match.xpath(xpath)&.text 
      case_file_date = Date.strptime(case_file_date, "%m-%d-%y") if case_file_date.present?
      return case_file_date
    end
    nil
  end


  def parse_parties_from_captcha_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@class='dw-search-result std-vertical-med-margin']"
    matches = parsed_page.xpath(xpath)
    list_of_hashes = []
    matches.each do |match|
      party_name = match.xpath("div[@class='dw-search-result-left']/div[2]")&.text&.squish
      party_type = match.xpath("div[@class='dw-search-result-left']/div[3]")&.text&.squish
      
      hash = {
        'party_name': party_name.gsub('face Name: ',''),
        'party_type': party_type.gsub('Participant Code: ',''),
      }

      list_of_hashes << hash
    end
    list_of_hashes
  end

  def get_court_name_by_id(id)
    if id == 348
      return "SUPREME+COURT"
    elsif id == 482
      return "COURT+OF+APPEALS+DIVISION+I"
    elsif id == 483
      return "COURT+OF+APPEALS+DIVISION+II"
    elsif id == 484
      return "COURT+OF+APPEALS+DIVISION+III"
    end
  end

  def parse_form_results_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@class='dw-search-content']//a"
    parsed_page.xpath(xpath)
  end

  def get_link_from_page_result_divs(div)
    div.values[0]
  end


  def parse_activites(file_content)
    # Data is present in script as a json array jo we will just get the data by simple splitting (no complex parsing)
    first_split = file_content.split("var tabledata = ")
    data = first_split[1].split("];")[0]  
    data
  end

  def parse_activites_text(data)
    all_rows = data[1..-1].squish.split("{")
    activites = []
    all_rows.each do |row|
      if row != ""
        hash = eval("{" + row.split("}")[0] + "}")
        activites << hash
      end
    end
    activites
  end

  def activites_helper(list_of_activites, court_id, case_id, data_source_url)
    list_of_hashes = []
    list_of_activites.each do |h|
      temp_hash = {}
      temp_hash['court_id'] = court_id
      temp_hash['case_id'] = case_id
      temp_hash['activity_date']  = Date.strptime(h[:eventDate], "%m-%d-%y")
      temp_hash['activity_type'] = h[:eventDescription]
      temp_hash['data_source_url'] = data_source_url
      # temp_hash[''] = h [:action]
      list_of_hashes << temp_hash
    end
    list_of_hashes
  end

  private

  def parse_opinon_information_sheet_table(table_div)
    rows = table_div.css('tr')
    hash = {}
    rows.each do |row|
      if row&.text.include?('Docket Number')
        hash['case_id']  = row.text.gsub("Docket Number:","").squish
      elsif row&.text.include?("Title of Case")
        hash['case_name']  = row.text.gsub("Title of Case:","").squish
      # elsif row&.text.include?("File Date:")
        # hash['date_file'] = row.text.gsub("File Date:","").squish
      # elsif row&.text.include?("Argument Date")
        # hash['agreement_date'] = row.text.gsub("Argument Date","").squish.gsub("Oral","")
      end
    end
    hash
  end

  def get_court_id(text)
    if text&.include?("Supreme Court of the State of Washington")
      return 348
    elsif text&.include?("Court of Appeals Division III")
      return 484
    elsif text&.include?("Court of Appeals Division II")
      return 483
    elsif text&.include?("Court of Appeals Division I")
      return 482
    end
    nil
  end

  def parse_source_of_appeal_table(table_div)
    hash = {}
    rows = table_div.css('tr')
    
    rows.each do |row|
      if row&.text.include?("Date filed:")
        date = row.text.gsub("Date filed:","").squish
        hash['lower_judgement_date'] = Date.strptime(date,"%m/%d/%Y") if date.present?
      elsif row&.text.include?('Judge signing:')
        hash['lower_judge_name'] = row.text.gsub("Judge signing:","").squish
      elsif row&.text.include?('Docket No:')
        hash['lower_case_id'] = row.text.gsub("Docket No:","").squish
      elsif row&.text.include?('Appeal from')
        hash['lower_court_name'] = row.text.gsub("Appeal from","").squish
      end
    end
    hash
  end
  
  def parse_justices_table(table_div)
    judges_names = table_div.css('tr').map(&:text).join("|")
    list_of_words_to_remove = ["Majority Author","Signed Dissent","Signed Majority","Dissent Author"]
    list_of_words_to_remove.each do |word|
      judges_names.gsub!(/#{word}/,"")
    end
    judges_names
  end

  def parse_counsel_of_record_table(table_div)
    rows = table_div.css('tr')
    parties = parse_parties_records(rows)
    list_of_parties = []
    parties.keys.each do |party_type|
      parties[party_type].each do |party|
        list_of_parties << parse_party(party_type , party)
      end
    end
    # parties.each do |party|
    #   list_of_parties << parse_partie(party)
    # end
    list_of_parties
  end

  def parse_parties_records(list)
    temp = []
    hash = {}

    all_party_types = list.select{|x| x.children[0].attributes["colspan"]&.value == "2" && x.text != "" }
    
    all_party_types.each do |party_type|
      hash[party_type.text] = []
    end
    
    party_type = list[0].text

    list[1..-1].each do |row|
      if row.children[0].attributes["colspan"]&.value == "2" and row.text != ""
        hash[party_type] << temp if temp.present?
        temp = []
        party_type = row.text
      elsif row.children[0].attributes["colspan"]&.value == "2" and row.text == ""
        hash[party_type] << temp if temp.present?
        temp = []
      else
        temp.append(row.text)
      end
    end
    hash[party_type] << temp if temp.length >= 3
    hash
  end

  def parse_party(party_type, list)
    hash = {}
    hash['party_type'] = party_type&.squish
    hash['party_name'] = list[0]&.squish

    hash['party_law_firm'] = list[1]&.squish if list.length >= 4
    hash['party_address'] = list[2]&.squish if list.length >= 4

    if list.length == 3
      # if digits are there assuming it will be party_address else it will be party law firm
      if list[1].match(/\d{2,}/).to_s == ""
        hash['party_law_firm'] = list[1]&.squish
      else
        hash['party_address'] = list[1]&.squish
      end
    end

    hash['party_city'] = extract_city(list[-1])
    hash['party_state'] = extract_state(list[-1])
    
    hash['party_zip'] = list[-1]&.match(/\d{2,}+-\d+{2,}/)&.to_s
    if hash['party_zip'] == nil
      hash['party_zip'] = list[-1]&.match(/\d{2,}/)&.to_s
    end
    hash['party_description'] = nil
    hash['is_lawyer'] = 1
    hash
  end

  def _parse_parties_records(list)
    records = []
    temp = []
    party_type = list[0].text
    list.each do |row|
      if row.children[0].attributes["colspan"]&.value == "2" and row.text != ""
        party_type = row.text
        if temp != []
          temp.append(party_type)
          records.append(temp) if temp.length >= 5
        end
        temp = []
        next
      elsif row.text != ""
        temp.append(row.text)
      elsif row.text == ""
        temp.append(party_type)
        records.append(temp) if temp.length >= 5
        temp = []
      end
    end
    temp.append(party_type) if temp.length >= 4
    records.append(temp)
    records
  end

  def parse_partie(list)
    hash = {}
    hash['party_name'] = list[0]&.squish
    hash['party_type'] = list[-1]&.squish
    hash['party_law_firm'] = list[1]&.squish
    hash['party_address'] = list[2]&.squish
    city_state  = [list[-2],list[-3]].compact.join(" ")
    hash['party_city'] = extract_city(city_state)
    hash['party_state'] = extract_state(city_state)
    hash['party_zip'] = list[-2]&.match(/\d{2,}+-\d+{2,}/)&.to_s    
    if hash['party_zip'] == nil
      hash['party_zip'] = list[-2]&.match(/\d{2,}/)&.to_s
    end
    hash['party_description'] = nil
    hash['is_lawyer'] = 1
    hash
  end

  
  def extract_state(address)
    if address.present?
      @all_states.each do |state|
        if address.downcase.gsub(/\.|,/,"").split(' ').include?(state.downcase)
          return state
        end
      end
    end
    nil
  end

  def extract_city(address)
    if address.present?
      @all_cities.each do |city|
        if address.downcase.split(' ').include?(city.downcase)
          return city
        end
      end
      @all_cities.each do |city|
        if address.downcase.include?(city.downcase)
          return city
        end
      end
    end
    nil
  end

end