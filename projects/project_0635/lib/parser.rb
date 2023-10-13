class Parser < Hamster::Parser

  def parse_page(html)
    Nokogiri::HTML(html.force_encoding('utf-8'))
  end

  def check_next_page(element)
    element.css('a').select{|e| e.text.include? 'Next'}.empty?
  end

  def get_url(element)
    url = element.css(".pagelinks a").select{|a| a.text.include? "Next"}[0]["href"]
    "https://apps.tn.gov/tncamp/public/replist.htm#{url}"
  end

  def parse_committees(page, run_id, hash_array)
    all_rows = page.css("#results").css("tbody tr")
    all_rows.each_with_index do |row, index|
      data_hash = {}
      all_columns = row.css("td")
      data_hash[:committee_name] = all_columns[0].text
      data_hash[:address] , data_hash[:city_state_zip], data_hash[:phone], data_hash[:email] = parse_address(all_columns[1])
      data_hash[:treasurer_name] = all_columns[2].text
      data_hash[:treasurer_address], data_hash[:treasurer_city_state_zip], data_hash[:treasurer_phone], data_hash[:treasurer_email] = parse_address(all_columns[3])
      data_hash[:party_affiliation] = all_columns[4].text
      data_hash[:report_list_link] = "https://apps.tn.gov#{all_columns[-1].css("a")[0]['href']}"
      data_hash[:office_sought] = all_columns[5].text
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
      hash_array << data_hash
    end
    hash_array
  end

  def parse_reports(committe_id, page, run_id, report_link, hash_array)
    records = page.css("#results").css("tbody tr")
    lower_date_limit = DateTime.strptime("01/01/2016","%m/%d/%Y").to_date
    records.each_with_index do |row, index_no|
      data_hash = {}
      all_columns = row.css("td")
      date_check = DateTime.strptime(all_columns[-1].text,"%m/%d/%Y").to_date rescue nil
      next if date_check < lower_date_limit
      data_hash[:committee_id] = committe_id
      data_hash[:election] = all_columns[0].text
      data_hash[:report_name] = all_columns[1].text
      data_hash[:submited_on] = date_check
      data_hash[:report_link] = "https://apps.tn.gov#{all_columns[1].css("a")[0]['href']}"
      data_hash[:depreciated] = all_columns[-2].text.strip
      data_hash[:depreciated] = data_hash[:depreciated] != "" ? 1 : 0
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash[:data_source_url] = report_link
      data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
      hash_array << data_hash
    end
    hash_array
  end

  def contributions_unitem(page, report, run_id, contributions_array)
    data_hash = {}
    data_hash[:report_id] = report[0]
    data_hash[:committe_id] = report[1]
    data_hash[:contributor_name], data_hash[:contributor_address], data_hash[:contributor_city_state_zip] = "UNITEMIZED"
    data_hash[:date] = report[3]
    data_hash[:amount] = page.css("div.row.control-group.report-row-dashed")[0].text.strip.gsub(/[$,]/,'').to_f
    data_hash[:received_for] = nil
    data_hash[:c_p] = nil
    data_hash[:depreciated] = report[4]
    data_hash[:data_source_url] = report[2]
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    contributions_array << data_hash  unless data_hash.empty?
  end

  def expenditures_unitem(page, report, run_id, expenditures_array)
    table = page.css("#unitemized").first.css("tbody tr") rescue nil
    return [] if table.nil?
    table.each_with_index do |row,index|
      data_hash = {}
      data_hash[:report_id] = report[0]
      data_hash[:committe_id] = report[1]
      data_hash[:vendor_name], data_hash[:vendor_address], data_hash[:vendor_city_state_zip]  = "UNITEMIZED"
      data_hash[:purpose] = row.css("td")[0].text.force_encoding("windows-1251").encode('utf-8').squish
      data_hash[:date] = report[3]
      data_hash[:amount] = row.css("td")[1].text.strip.gsub(/[$,]/,'').to_f
      data_hash[:depreciated] = report[4]
      data_hash[:data_source_url] = report[2]
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
      expenditures_array << data_hash unless data_hash.empty?
    end
    expenditures_array
  end

  def expenditures_item(page, report, run_id, expenditures_array)
    table = page.css("#expenditure").first.css("tbody tr") rescue nil
    table = [] if table.nil?
    table.each_with_index do |row,index|
      data_hash = {}
      data_hash[:report_id] = report[0]
      data_hash[:committe_id] = report[1]
      data_hash[:vendor_name], data_hash[:vendor_address], data_hash[:vendor_city_state_zip] = parse_name(row.css("td")[0], row, report[2], page)
      data_hash[:purpose] = row.css("td")[2].text.force_encoding("windows-1251").encode('utf-8').squish
      date = row.css("td").select{|a| !(a.text.force_encoding("windows-1251").encode('utf-8').squish.scan(/[0-9]\//).empty?)}[0]
      data_hash[:date] = DateTime.strptime(date.text.squish,"%m/%d/%Y").to_date  rescue nil
      data_hash[:amount] = row.css("td").select{|a| a.text.include? "$"}[0].text.gsub(/[$,]/,'').to_f
      data_hash[:depreciated] = report[4]
      data_hash[:data_source_url] = report[2]
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
      expenditures_array << data_hash unless data_hash.empty?
    end
    expenditures_array
  end

  def contributions_item(page, report, run_id, contributions_array)
    table = page.css("#contribution.responsive.responsive-active")[0].css("tbody tr") rescue nil
    table = [] if table.nil?
    table.each_with_index do |row,index|
      data_hash = {}
      data_hash[:report_id] = report[0]
      data_hash[:committe_id] = report[1]
      data_hash[:contributor_name], data_hash[:contributor_address], data_hash[:contributor_city_state_zip] = parse_name(row.css("td")[0], row, report[2], page)
      date = row.css("td").select{|a| !(a.text.squish.scan(/[0-9]\//).empty?)}[0]
      data_hash[:date] = DateTime.strptime(date.text.squish, "%m/%d/%Y").to_date rescue nil
      data_hash[:amount] = row.css("td").select{|a| a.text.include? "$"}[0].text.strip.gsub(/[$,]/,'').to_f
      data_hash[:received_for] = row.css("td").select{|a| (a.text.include? "Primary") || (a.text.include? "General")}[0].text.squish  rescue nil
      data_hash[:c_p] = row.css("td")[1].text.squish
      data_hash[:depreciated] = report[4]
      data_hash[:data_source_url] = report[2]
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
      contributions_array << data_hash unless data_hash.empty?
    end
    contributions_array
  end

  private

  def parse_name(element, row, report, page)
    noko_element = element.css('text()')
    name = noko_element[0]&.text.squish
    address = noko_element[1]&.text.squish
    city = noko_element[2]&.text.squish
    [name, address, city]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def parse_address(address)
    noko_element = address.css('text()')
    address = noko_element[0]&.text
    temp_city = noko_element[1]&.text
    city_state_zip = (temp_city.include? ",")? temp_city : temp_city + noko_element[2]&.text rescue nil
    email = noko_element.select{|a| a.text.include? "@"}[0].text rescue nil
    phone = noko_element.select{|a| a.text.include? "("}[0].text rescue nil
    [address, city_state_zip, phone, email]
  end
end
