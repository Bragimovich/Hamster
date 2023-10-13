# frozen_string_literal: true
require 'iconv'

class Parser < Hamster::Parser

  def read_pdf(file)
    begin
      @reader = PDF::Reader.new(file)
    rescue
      false
    end
  end

  def get_content(file)
    content = File.read(file).force_encoding('iso-8859-1').encode('utf-8').match(/.*%%EOF/m)
    content = Iconv.iconv('ISO-8859-1', 'UTF-8', content.to_s).first
    content
  end

  def get_form_values(response)
    page = parse_page(response)
    event_val = search_value(page, '#__EVENTVALIDATION')
    view_state = search_value(page, '#__VIEWSTATE')
    view_state_gen = search_value(page, '#__VIEWSTATEGENERATOR')
    [event_val,view_state,view_state_gen]
  end

  def get_ctl_values_and_page_count(response)
    page = parse_page(response)
    begin
      required_rows = page.css('#ctl00_ContentPlaceHolder1_ResultsGridView').css('tr').select{ |e| e.css('a').count == 1 }
      ctl_values = required_rows.map{ |e| e.css('a').first['href'].split('$')[-2] }
      total_page = page.css('#ctl00_ContentPlaceHolder1_ResultsGridView_ctl01_CurrentPageLabel').first.text.scan(/\d+/).first.to_i
      [ctl_values,total_page]
    rescue
      [[],0]
    end
  end

  def get_pdf_ids(response)
    page = parse_page(response)
    page.css('a').reject{ |e| e['href'].nil? }.select{ |e| e['href'].downcase.include? 'reportid' }.map{ |e| e['href'].split('=').last }.uniq rescue []
  end

  def parse_contribution_data(file, run_id, filer_id)
    md5_array = []
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.select{ |e| e.join.downcase.include? 'name' }.first.map{ |e| e.to_s.downcase.squish } rescue nil
    return [] if (headers.nil?)
    rows.each do |row|
      next if (required_value?(row,'name'))
      data_hash = {}
      data_hash[:filer_id]                = filer_id
      data_hash[:filer_firstname]         = get_row_value(row, headers, 'firstname').gsub('&quot;','')
      data_hash[:filer_lastname]          = get_row_value(row, headers, 'lastname').gsub('&quot;','')
      data_hash[:report_code]             = get_row_value(row, headers, 'reportcode')
      data_hash[:report_type]             = get_row_value(row, headers, 'reporttype')
      data_hash[:report_number]           = get_row_value(row, headers, 'reportnumber')
      data_hash[:type]                    = get_row_value(row, headers, 'contributiontype')
      data_hash[:contribution_type_code]  = get_row_value(row, headers, 'contributortypecode')
      data_hash[:source_name]             = get_row_value(row, headers, 'contributorname')
      data_hash[:source_address]          = "#{get_row_value(row, headers, 'contributoraddr1')} #{get_row_value(row, headers, 'contributoraddr2')}".squish
      data_hash[:source_city]             = get_row_value(row, headers, 'contributorcity')
      data_hash[:source_state]            = get_row_value(row, headers, 'contributorstate')
      data_hash[:source_zip]              = get_row_value(row, headers, 'contributorzip')
      data_hash[:description]             = get_row_value(row, headers, 'contributiondescription')
      data_hash[:contribution_date]       = get_date_required_format(get_row_value(row, headers, 'contributiondate'))
      data_hash[:amount]                  = get_row_value(row, headers, 'contributionamt')
      data_hash[:md5_hash]                = create_md5_hash(data_hash)
      data_hash[:data_source_url]         = "https://www.ethics.la.gov/CampaignFinanceSearch/SearchByName.aspx"
      data_hash[:filer_fullname]          = "#{data_hash[:filer_firstname]} #{data_hash[:filer_lastname]}".squish
      data_hash[:source_complete_address] = "#{data_hash[:source_address]} #{data_hash[:source_city]} #{data_hash[:source_state]} #{data_hash[:source_zip]}".squish
      data_hash[:report_link]             = "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{data_hash[:report_number].split('-').last}"
      data_hash[:run_id]                  = run_id
      data_hash[:touched_run_id]          = run_id
      data_hash                           = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_expenditure_data(file, run_id, filer_id)
    md5_array = []
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.select{ |e| e.join.downcase.include? 'name' }.first.map{ |e| e.to_s.downcase.squish } rescue nil
    return [] if (headers.nil?)
    rows.each do |row|
      next if (required_value?(row,'name'))
      data_hash = {}
      data_hash[:filer_id]                   = filer_id
      data_hash[:filer_firstname]            = get_row_value(row, headers, 'firstname').gsub('&quot;','')
      data_hash[:filer_lastname]             = get_row_value(row, headers, 'lastname').gsub('&quot;','')
      data_hash[:report_code]                = get_row_value(row, headers, 'reportcode')
      data_hash[:report_type]                = get_row_value(row, headers, 'reporttype')
      data_hash[:report_number]              = get_row_value(row, headers, 'reportnumber')
      data_hash[:recipient_name]             = get_row_value(row, headers, 'recipientname')
      data_hash[:recipient_address]          = "#{get_row_value(row, headers, 'recipientaddr1')} #{get_row_value(row, headers, 'recipientaddr2')}".squish
      data_hash[:recipient_city]             = get_row_value(row, headers, 'recipientcity')
      data_hash[:recipient_state]            = get_row_value(row, headers, 'recipientstate')
      data_hash[:recipient_zip]              = get_row_value(row, headers, 'recipientzip')
      data_hash[:description]                = get_row_value(row, headers, 'expendituredescription')
      data_hash[:schedule]                   = get_row_value(row, headers, 'schedule')
      data_hash[:candidate_beneficiary]      = get_row_value(row, headers, 'candidatebeneficiary')
      data_hash[:expenditure_date]           = get_date_required_format(get_row_value(row, headers, 'expendituredate'))
      data_hash[:amount]                     = get_row_value(row, headers, 'expenditureamt')
      data_hash[:md5_hash]                   = create_md5_hash(data_hash)
      data_hash[:data_source_url]            = "https://www.ethics.la.gov/CampaignFinanceSearch/SearchByName.aspx"
      data_hash[:filer_fullname]             = "#{data_hash[:filer_firstname]} #{data_hash[:filer_lastname]}".squish
      data_hash[:recipient_complete_address] = "#{data_hash[:recipient_address]} #{data_hash[:recipient_city]} #{data_hash[:recipient_state]} #{data_hash[:recipient_zip]}".squish
      data_hash[:report_link]                = "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{data_hash[:report_number].split('-').last}"
      data_hash[:run_id]                     = run_id
      data_hash[:touched_run_id]             = run_id
      data_hash                              = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_pac_data(report_number, filer_id, run_id)
    md5_array = []
    data_array = []
    return [[],[]] unless (check_report_type('COMMITTEE’S REPORT') || check_report_type('REPORT FOR PROPOSITION/RECALL ELECTIONS') || check_report_type('COMMITTEE’S SPECIAL REPORT') || check_report_type('SPECIAL REPORT FOR PROPOSITIONS/RECALL ELECTIONS'))
    first_page = reader.pages.first.text.scan(/^.+/)
    filed_date = first_page.select{ |e| e.downcase.include? 'date filed' }.first.scan(/\d{1,2}\/\d{1,2}\/\d{4}/).first
    if (check_report_type('COMMITTEE’S REPORT') || check_report_type('REPORT FOR PROPOSITION/RECALL ELECTIONS'))
      chair_person = first_page.select{ |e| e.downcase.include? 'chairperson' }.reject{ |e| e.include? 'including' }.first.split('  ').reject{ |e| e.empty? }.first.squish
    else
      chair_person_index = first_page.index(first_page.select{ |e| e.downcase.include? 'chairperson' }.first)
      chair_person = first_page[chair_person_index + 1].squish rescue nil
    end
    pac_name = first_page.select{ |e| e.downcase.include? 'report number' }.first.split('  ').reject{ |e| e.empty? }.first.squish
    address_1_index = first_page.index(first_page.select{ |e| e.downcase.include? 'report number' }.first) + 1
    address_1 = first_page[address_1_index].split('  ').reject{ |e| e.empty? }.first.squish
    address_1 = first_page[address_1_index + 1].split('  ').reject{ |e| e.empty? }.first.squish if (address_1.scan(/[A-Za-z]/).empty?)
    address_2 = reader.pages.first.text.scan(/^[^,\n]+,\s*[A-Z]{2}\s*\d{5}$/).first.squish rescue nil
    address_2 = reader.pages.first.text.scan(/^[^,\n]+,\s*[A-Z]{2}\s*\d{5}(?:-\d{4})?$/).first.squish if (address_2.nil?) rescue nil
    address_2 = reader.pages.first.text.scan(/([A-Za-z\s]+),\s([A-Z]{2})\s(\d{5})/).map { |match| "#{match[0]}, #{match[1]} #{match[2]}" }.first.squish if (address_2.nil?) rescue nil
    city, state, zip = pac_address_split(address_2)
    data_hash = {}
    data_hash[:pac_name]                   = pac_name
    data_hash[:filer_id]                   = filer_id
    data_hash[:filing_date]                = get_date_required_format(filed_date)
    data_hash[:report_type]                = 'PAC'
    data_hash[:pac_complete_address]       = "#{address_1} #{address_2}".squish
    data_hash[:pac_city]                   = city
    data_hash[:pac_state]                  = state
    data_hash[:pac_zip]                    = zip
    data_hash[:report_number]              = report_number
    data_hash[:pac_chair_person]           = chair_person
    data_hash[:md5_hash]                   = create_md5_hash(data_hash)
    data_hash[:data_source_url]            = "https://www.ethics.la.gov/CampaignFinanceSearch/SearchByName.aspx"
    data_hash[:report_link]                = "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{report_number}"
    data_hash[:run_id]                     = run_id
    data_hash[:touched_run_id]             = run_id
    data_array << mark_empty_as_nil(data_hash)
    md5_array << data_hash[:md5_hash]
    [data_array,md5_array]
  end

  def parse_committee_data(report_number, filer_id, run_id)
    md5_array = []
    pg_1_text = reader.pages.first.text
    filed_date = parse_filed_date(pg_1_text)
    if reader.pages.count > 1
      text = reader.pages[1].text
    else
      text = reader.pages[0].text
    end
    committee_chair_person = text.scan(/^.+/).select{|e| e.include? 'Chairperson:'}.first.split('  ').last.split(':').last.squish rescue nil
    committee_name = parse_committee_name(text)
    committee_address = parse_committee_address(text)
    array = []
    unless committee_name.empty?
      committee_name.each_with_index do |name, ind|
        address = committee_address[ind] rescue ""
        if address != "" or address != "."
          city, state, zip_code = parse_city_state_zip(address)
        elsif address == ", LA"
          city, zip_code = ""
          state = "LA"
        else
          city, state, zip_code = ""
        end
        data_hash = {
          filer_id: filer_id,
          committee_chair_person: committee_chair_person,
          committee_name: name,
          committee_complete_address: address,
          committee_city: city,
          committee_state: state,
          committee_zip: zip_code,
          report_number: report_number,
          report_link: "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{report_number}",
          filing_date:filed_date
        }
        md5_hash = create_md5_hash(data_hash)
        data_hash = data_hash.merge(:md5_hash => md5_hash)
        data_hash = data_hash.merge(:data_source_url => 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchByName.aspx')
        data_hash = data_hash.merge(:touched_run_id => run_id)
        data_hash = data_hash.merge(:run_id => run_id)
        data_hash = mark_empty_as_nil(data_hash)
        md5_array << data_hash[:md5_hash]
        array << data_hash
      end
    end
    [array,md5_array]
  end

  def parse_candidates_data(report_number, filer_id, run_id)
    md5_array = []
    array = []
    text = reader.pages.first.text
    candidate_name = parse_name(text)
    candidate_address = parse_address(text)
    if candidate_address != ""
      city, state, zip_code = parse_city_state_zip(candidate_address)
    end
    filed_date = parse_filed_date(text)
    bank = parse_bank(text)
    bank_address = parse_bank_address(text)
    candidate_office_sought = parse_candidate_office_sought(text)
    treasurer_name = parse_treasurer_name(text)
    treasurer_address = parse_treasurer_address(text)
    report_preparing_person_name = parse_report_preparing_person_name(text)
    daytime_telephone = parse_daytime_telephone(text)
    candidate_election_date = parse_candidate_election_date(text)
    data_hash = {
      filer_id: filer_id,
      candidate_name: candidate_name,
      candidate_complete_address: candidate_address,
      candidate_city: city,
      candidate_state: state,
      candidate_zip: zip_code,
      filing_date: filed_date,
      report_number: report_number,
      candidate_financial_institution_name: bank,
      candidate_financial_institution_address: bank_address,
      candidate_treasurer_name: treasurer_name,
      candidate_treasurer_address: treasurer_address,
      report_preparing_person_name: report_preparing_person_name,
      daytime_telephone: daytime_telephone,
      candidate_election_date: candidate_election_date,
      report_link: "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{report_number}"
    }
    md5_hash = create_md5_hash(data_hash)
    data_hash = data_hash.merge(:md5_hash => md5_hash)
    data_hash = data_hash.merge(:data_source_url => 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchByName.aspx')
    data_hash = data_hash.merge(:touched_run_id => run_id)
    data_hash = data_hash.merge(:run_id => run_id)
    data_hash = mark_empty_as_nil(data_hash)
    array << data_hash
    md5_array << data_hash[:md5_hash]
    [array,md5_array]
  end

  private

  attr_reader :reader

  def check_report_type(key)
    return true if reader.pages.first.text.include? key
    false
  end

  def get_row_value(row, headers ,key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index].to_s.squish unless value_index.nil?
  end

  def search_value(page, key)
    page.css(key).first['value'] rescue nil
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def parse_csv_file(file)
    CSV.foreach(file)
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def required_value?(row,key)
    return true if (row.join.downcase.include? key)
    false
  end

  def get_date_required_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date rescue nil
  end

  def pac_address_split(address)
    unless address.nil?
      city = address.split(',').first.squish
      state = address.split(',').last.squish.split.first
      zip = address.split(',').last.squish.split.last
      [city,state,zip]
    else
      nil
    end
  end

  def parse_committee_address(text)
    rows = text.split("\n")
    if !rows[0..1].join.include? "FOR PRINCIPAL CAMPAIGN COMMITTEES ONLY"
      return ""
    end
    array = []

    str = rows.select{|e| e.include? "Principal Campaign Committee" }.first
    unless str.nil?
      ind = rows.index(str)
      address = rows[ind + 3..ind+6].join(" ") rescue ""
      array << address.squish
    end
    str = rows.select{|e| e.include? "Committee's Chairman" }.first

    unless str.nil?
      ind = rows.index(str)
      address = rows[ind + 3..ind+6].join(" ") rescue ""
      array << address.squish
    end
    array
  end

  def parse_committee_name(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "PRINCIPAL CAMPAIGN COMMITTEES ONLY"
      return ""
    end
    array = []
    str = rows.select{|e| e.include? "Principal Campaign Committee" }.first
    unless str.nil?
      ind = rows.index(str)
      name = rows[ind + 2].strip rescue ""
      array << name
    end
    str = rows.select{|e| e.include? "Committee's Chairman" }.first
    unless str.nil?
      ind = rows.index(str)
      name = rows[ind + 2].strip rescue ""
      array << name
    end
    array
  end

  def parse_candidate_office_sought(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end

    str = rows.select{|e| e.include? "2. Office Sought" }.first
    ind = rows.index(str)
    data = rows[ind+3..ind+8].reject{|e| !e.include? "               "}
    name = ""

    data.each do |str|
      str_array = str.split("                  ").reject{|e| e == ""}

      next if str_array[-1].include? "Report"
      if str_array.count() == 2
        name += str_array[1] rescue ""
        name += " "
      elsif str_array.count == 1
        name += str_array[0]  rescue ""
        name += " "
      elsif str_array.count == 3
        name += str_array[1]  rescue ""
        name += " "
      end
    end
    name = name.split("Report").first
    name = name.split("Date").first
    name.squish
  end

  def parse_candidate_election_date(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    str = rows.select{|e| e.include? "3. Date of Primary" }.first
    if str.nil?
      str = rows.select{|e| e.include? "Date of Election" }.first
    end
    if str.nil?
      return ""
    end
    ind = rows.index(str)
    if rows[ind].include? "Future"
      return "Future"
    end
    regex = /(\d{2}\/\d{2}\/\d{4})/
    date = regex.match(rows[ind])
    if date
      date = date[1]
    else
      if rows[ind+1].include? "Future"
        return "Future"
      end
      date = regex.match(rows[ind+1])
      if date
        date = date[1]
      end
    end
    get_date_required_format(date)
  end

  def parse_daytime_telephone(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    str = rows.select{|e| e.include? "Daytime Telephone"}.first
    return "" if str.nil?
    ind = rows.index(str)
    phone = rows[ind].split("  ").last.strip rescue ""
    if phone == "Daytime Telephone" or phone == "--"
      phone = ""
    end
    phone
  end

  def parse_report_preparing_person_name(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    str = rows.select{|e| e.include? "9. Name of Person Preparing Report"}.first
    return "" if str.nil?
    ind = rows.index(str)
    name = rows[ind].split("  ").last.strip rescue ""
    if name == "9. Name of Person Preparing Report"
      name = ""
    end
    name
  end

  def parse_treasurer_address(text)
    rows = text.split("\n").reject{|e| e == ""}
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    str = rows.select{|e| e.include? "7. Full Name and Address of Treasurer"}.first
    return "" if str.nil?
    ind = rows.index(str)

    if rows[ind+3] != "banks, savings and loan associations, or money" and rows[ind+3] != "market mutual fund as the depository of all"
      address = rows[ind + 3..ind + 5].each_with_index.map { |e, i| i == 0 ? e.split("         ").last : (e.include?(", LA") ? e.split("         ").last : "") }.reject{|e| e== ""}.join(" ").squish rescue ""
    else
      address = ""
    end
    address.nil? ? address : address.squish
    address.squish
  end

  def parse_treasurer_name(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end

    str = rows.select{|e| e.include? "7. Full Name and Address of Treasurer"}.first
    ind = rows.index(str)
    name = rows[ind+2].split("        ").last.strip rescue ""
    if name.include? "banks, savings and loan associations, or money"
      if rows[ind+1] == "(You are required by law to use one or more"
        name = ""
      else
        name = rows[ind+1].split("        ").last.strip rescue ""
      end
    end
    name
  end

  def parse_bank_address(text)
    rows = text.split("\n")

    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    str = rows.select{|e| e.include? "9. Name of Person Preparing Report"}.first
    ind = rows.index(str)
    address = rows[ind-6] + " " + rows[ind-5] rescue ""
    address.strip
  end

  def parse_bank(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end

    bank_name = rows.select{|e| e.include? "BANK"}.first
    if bank_name.nil?
      str = rows.select{|e| e.include? "6. Name and Address of Financial Institution"}.first
      ind = rows.index(str)
      begin
        bank_name = rows[ind+7]
      rescue
        bank_name = ""
      end
    end
    bank_name
  end

  def parse_filed_date(text)
    rows = text.split("\n")
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    text = text.scan(/^.+/)
    str = text.select{|e| e.include? "Date Filed:"}.first
    date = str.split("Date Filed:").last.strip
    get_date_required_format(date)
  end

  def parse_city_state_zip(address)
    match = address.match(/^(.*),\s*([A-Z]{2})\s+(\d{5})(?:\-\d{4})?$/)

    city = match[1].split.last rescue ""
    state = match[2] rescue ""
    zip_code = match[3] rescue ""
    [city, state, zip_code]
  end

  def parse_address(text)
    rows = text.split("\n").reject{|e| e == ""}
    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end
    postfix = ""
    str = rows.select{|e| e.include? "Report Number:"}.first
    ind = rows.index(str)
    if rows[ind+1] == ""
      ind = ind + 2
    end


    candidate_address =  rows[ind+1].split("               ").first.strip() + " "


    if candidate_address == " " or candidate_address.include? ", LA"
      candidate_address =  rows[ind].split("               ").first.strip() + " "
      postfix += rows[ind+2..ind+3].map{|e| e.split("               ").first.strip rescue ""}.join(" ")
      candidate_address += postfix.to_s
      candidate_address = candidate_address.squish
      return candidate_address
    end

    begin
      postfix += rows[ind+2..ind+3].map{|e| e.split("               ").first.strip rescue ""}.join(" ")
      unless postfix.include? ", LA"
        postfix = rows[ind+2..ind+4].map{|e| e.split("               ").first.strip rescue ""}.join(" ")
      end
      unless postfix.include? ", LA"
        postfix = rows[ind+2..ind+5].map{|e| e.split("               ").first.strip rescue ""}.join(" ")
      end
    rescue
      postfix = postfix.nil? ? "" : postfix
      postfix += rows[ind+2..ind+3].map{|e| e.split("               ").first.strip rescue ""}.join(" ")
    end

    candidate_address += postfix.to_s
    candidate_address = candidate_address.squish
    candidate_address
  end

  def parse_name(text)
    rows = text.split("\n")

    unless rows[0..1].join.include? "CANDIDATE’S SPECIALREPORT" or rows[0..1].join.include? "CANDIDATE’S REPORT" or rows[0..1].join.include? "CANDIDATE’S SPECIAL REPORT"
      return ""
    end

    text = text.scan(/^.+/)
    str = text.select{|e| e.include? "Report Number"}.first
    ind = text.index(str)
    candidate_name =  text[ind].split("               ").first.strip()
    if candidate_name == ""
      candidate_name =  text[ind-1].split("               ").first.strip()
      if candidate_name.include? "Principal Campaign Committee"
        candidate_name =  text[ind+1].split("               ").first.strip()
      end
    end
    candidate_name
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

end
