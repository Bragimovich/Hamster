require_relative "./parser_helper.rb"
class Parser < Hamster::Parser

  include ParserHelper

  LEGIS_DOMAIN  = "https://capitol.texas.gov/Committees/"

  def parsing_html(page_html)
    Nokogiri::HTML(page_html.force_encoding('utf-8'))
  end

  def get_legislature(page)
    page.css("#cboLegSess").css("option").select{|e| e.text.scan(/\d+/)[-1].to_i >= 2023}
  end

  def add_foreign_ids(data, id_senate, id_house)
    data["house_committee_id"]  = id_house
    data["senate_committee_id"] = id_senate
    data
  end

  def get_total_pages(pp)
    find_pages = pp.css("#lblMatches").text.split(" ")[-2].gsub(",",'').to_i/25
    find_pages += 1 if pp.css("#lblMatches").text.split(" ")[-2].to_i%25 != 0
    find_pages
  end

  def next_link(pp, index)
    if pp.css('img[alt="Navigate to next page"]').last.nil?
      link = pp.css("td.noPrint a").map{|a|a["href"]}[index]
    else
      link = pp.css('img[alt="Navigate to next page"]').last.parent['href']
    end
    link
  end

  def get_bill_links(document)
    document.css('table[width="95%"] a').map{|e| "https://capitol.texas.gov"+e['href'].gsub('..','')}.reject{|e| e.include? '#'}
  end

  def next_page_check(document)
    document.css('img[alt="Navigate to next page"]').count == 2
  end

  def page_number_check(document)
    document.css('td.noPrint a').text.last
  end

  def get_values(main)
    view_state = main.css("#__VIEWSTATE")[0]['value']
    generator = main.css("#__VIEWSTATEGENERATOR")[0]['value']
    previous_value = main.css("#__PREVIOUSPAGE")[0]['value']
    [view_state, generator, previous_value]
  end

  def get_legis_generator(page)
    view_generator = page.css("#__VIEWSTATEGENERATOR")[0]['value']
    view_state = page.css("#__VIEWSTATE")[0]['value']
    event_validation  = page.css("#__EVENTVALIDATION")[0]["value"]
    [view_generator, view_state, event_validation]
  end

  def get_legis(parsed_page)
    array = parsed_page.css("#ddlLegislature option").map{|option| option.text.strip}
    array = array.map { |el| el.split(" ")[0].gsub(/(st|nd|rd|th)/,'').to_i }
    [array.first]
  end

  def get_legis_links(parsed_page)
    parsed_page.css("#ctl00 ul li a").map{|a| a["href"]}
  end

  def get_bill_data(data, legislature, run_id)
    return if data.text.include?("Object moved")
    data_hash = {}
    data_hash["last_action"] = DateTime.strptime(data.css("#cellLastAction").text.split().first, "%m/%d/%Y").to_date rescue nil
    data_hash["year"] = legislature.split("_")[1].strip
    data_hash["bill_number"] = data.css("span#usrBillInfoTabs_lblBill").text
    data_hash["legislative_session"] = data.css("td").select{|a| a.text.include?"Legislative Session"}[0].text.split(":").last.squish
    data_hash["effective_date"] = get_effective_date(data)
    data_hash["caption_version"] = get_data_bills(data,"cellCaptionVersion")
    data_hash["caption_text"] = get_data_bills(data,"cellCaptionText")
    data_hash["author"] = get_data_bills(data,"cellAuthors")
    data_hash["sponsor"] = get_data_bills(data,"cellSponsors")
    data_hash["subject"] = get_data_bills(data,"cellSubjects")
    data_hash["house_committee"], data_hash["house_committee_link"], table_number = get_house_bill(data,"House Committee")
    data_hash["house_status"],  house_vote = get_bill_commitee_data(data, data_hash["house_committee"], table_number)
    data_hash.merge!(get_vote(house_vote, "house"))
    data_hash["senate_committee"], data_hash["senate_committee_link"], table_number = get_senate_bill(data,"Senate Committee")
    data_hash["senate_status"], senate_vote = get_bill_commitee_data(data, data_hash["senate_committee"], table_number)
    data_hash.merge!(get_vote(senate_vote, "senate"))
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash["data_source_url"] = create_link(data_hash["legislative_session"], data_hash["bill_number"])
    data_hash
  end

  def get_bill_actions(data, legislature, run_id)
    actions = data.css('form#Form1').css("table[@frame='hsides'] tr")[1..-1]
    hash_array = []
    return nil if actions.nil?
    actions.each do |action|
      data_hash = {}
      data_hash["year"] = legislature.split("_")[1].strip
      data_hash["bill_number"] = data.css("span#usrBillInfoTabs_lblBill").text
      data_hash["legislative_session"] = data.css("td").select{|a| a.text.include?"Legislative Session"}[0].text.split(":").last.squish
      data_hash["description"] = action.css('td')[1].text.squish
      data_hash["comment"] = action.css('td')[2].text.squish
      data_hash["comment"] = nil if data_hash["comment"].empty?
      data_hash["date"] = DateTime.strptime(action.css('td')[3].text.squish, "%m/%d/%Y").to_date rescue "-"
      data_hash["time"] = action.css('td')[4].text.squish
      data_hash["journal_page"] = action.css('td')[-1].text.squish.to_i
      data_hash.merge!(get_common(data_hash, run_id))
      data_hash["data_source_url"] = create_link(data_hash["legislative_session"], data_hash["bill_number"])
      hash_array << data_hash
    end
    hash_array
  end

  def parse_committee_data(data, link, run_id, committee_type)
    data = parsing_html(data)
    data_hash = {}
    committee_data = data.css("div#content table")[0].css("tr")[0].css("td").first.text
    data_hash["committee"] = committee_data.split("(")[0].squish
    data_hash["committee_code"] = committee_data.split("(")[-1].gsub(")", "")
    data_hash["clerk"] = get_committee_data(data, committee_type, "Clerk:")
    data_hash["legislature"] = get_committee_data(data, committee_type, "Legislature:").split("-")[0].squish
    data_hash["year"] = get_committee_data(data, committee_type, "Legislature:").split("-")[-1].squish
    data_hash["phone"] = get_committee_data(data, committee_type, "Phone:")
    data_hash["appointment_date"] = DateTime.strptime(get_committee_data(data, committee_type, "Appointment Date:"), "%m/%d/%Y").to_date rescue nil
    data_hash["room"] = get_committee_data(data, committee_type, "Room:")
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash["data_source_url"] = LEGIS_DOMAIN + link
    data_hash
  end

  def get_senate_housing_data(data, senate_id, link, run_id)
    data        = parsing_html(data)
    all_rows = data.css("table")[-1].css("tr")[1..-1]
    all_data = []
    all_rows.each do |row|
      data_hash = {}
      data_hash["committee_id"] = senate_id
      data_hash["title"], data_hash["full_name"] = row_data(row, senate_id, LEGIS_DOMAIN+link)
      data_hash["first_name"], data_hash["middle_name"], data_hash["last_name"] = name_spliting(data_hash["full_name"])
      data_hash.merge!(get_common(data_hash, run_id))
      data_hash["data_source_url"] = LEGIS_DOMAIN + link
      all_data << data_hash
    end
    all_data
  end

  def link_md5(link)
    Digest::MD5.hexdigest(link)
  end

end
