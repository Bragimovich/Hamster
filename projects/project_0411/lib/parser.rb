# frozen_string_literal: true

class Parser <  Hamster::Scraper

  COURT_ID = 342
  DOMAIN ="https://ujs.sd.gov"
  STATES = [ "Alaska", "Alabama", "Arkansas", "American Samoa", "Arizona", "California", "Colorado", "Connecticut", "District of Columbia", "Delaware", "Florida", "Georgia", "Guam", "Hawaii", "Iowa", "Idaho", "Illinois", "Indiana", "Kansas", "Kentucky", "Louisiana", "Massachusetts", "Maryland", "Maine", "Michigan", "Minnesota", "Missouri", "Mississippi", "Montana", "North Carolina", "North Dakota", "Nebraska", "New Hampshire", "New Jersey", "New Mexico", "Nevada", "New York", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Puerto Rico", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Virginia", "Virgin Islands", "Vermont", "Washington", "Wisconsin", "West Virginia", "Wyoming"]

  def pdf_parser(file_path, date, title, pdf_link, run_id, s3, page)
    @reader = PDF::Reader.new(file_path)
    fetch_pdf_page
    return [] if (@reverse_doc.empty?)
    parse_tables_data(pdf_link, date, title, run_id, s3, page)
  end

  def required_values(response)
    data = parse_body(response.body)
    __VIEWSTATE          = data.css("#__VIEWSTATE")[0]["value"]
    __EVENTVALIDATION    = data.css("#__EVENTVALIDATION")[0]["value"]
    __VIEWSTATEGENERATOR = data.css("#__VIEWSTATEGENERATOR")[0]["value"]
    [__EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR]
  end

  def get_inner_values(response)
    __VIEWSTATE          = response.body.split("__VIEWSTATE|")[1].split("|").first
    __EVENTVALIDATION    = response.body.split("__EVENTVALIDATION|")[1].split("|").first
    __VIEWSTATEGENERATOR = response.body.split("__VIEWSTATEGENERATOR|")[1].split("|").first
    [__EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR]
  end

  def get_links(response)
    doc = parse_body(response.body)
    doc.css("table.table.table-sm.table-striped tbody tr").map{|e| e.css("td")[-2].css("a")[0]["href"]}  
  end

  def get_pages_hash(response)
    doc= parse_body(response.body)
    pages= doc.css("#ContentPlaceHolder1_ChildContent1_DataList_Paging tr td a")[1..-1]
    pages_hash={}
    pages.map{|page| pages_hash[page.text] = page['href'].split("(").last.split(",").first.gsub("'","") }
    pages_hash
  end

  def get_title(response)
    doc = parse_body(response)
    table_rows = doc.css("table.table.table-sm.table-striped tbody tr")
    date       = table_rows.map{|e| e.css("td")[0].text} 
    title      = table_rows.map{|e| e.css("td")[1].text} 
    links      = table_rows.map{|e| e.css("td")[-2].css("a")[0]["href"]}  
    [date, title, links]
  end

  def parse_body(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def get_total_pages(page)
    page.css("#ContentPlaceHolder1_ChildContent1_Label_Page").text.split("of").last.squish.to_i
  end

  private

  def fetch_pdf_page(page_no = 0)
    @document = @reader.pages[page_no].text.scan(/^.+/)
    @reverse_doc = @document.reverse
  end

  def upload_file_to_aws(key, s3, page)
    s3.put_file(page, key, metadata={})
  end

  def parse_tables_data(pdf_link, date, title, run_id, s3, page)
    @case_info,@case_consolidations , @case_pdfs_on_aws, @case_relations_info_pdf, @case_party_attorny, @case_party = Array.new(6){[]}
    @source_url = DOMAIN + pdf_link
    ind = find_index("#")
    case_id = @document[ind].strip.scan(/\d+/).first
    case_info(case_id, date, title, run_id)
    case_consolidations(case_id, run_id)
    case_party(case_id, run_id)
    case_party_attorny(case_id, run_id)
    case_pdfs_on_aws(case_id, pdf_link, run_id, s3, page)
    case_relations_info_pdf
    [@case_info, @case_consolidations, @case_pdfs_on_aws, @case_relations_info_pdf, @case_party_attorny, @case_party]
  end

  def get_party_details(value)
    split_array = value.split('   ').reject{|s| s == ""}
    index_value = split_array.find_index{|s| (s.include?("Defendant")) || (s.include?("Plaintiff")) || (s.include?("Appellant")) || (s.include?("Appelle")) || (s.include?("Petitioner")) || (s.include?("Respondent")) || (s.include? ', Provider')}
    party_name_array = split_array[0...index_value].join(",") rescue []
    party_type_array = split_array[index_value..-1].join(",")
    [party_name_array, party_type_array]
  end

  def get_all_parties(party_record)
    party_name_array  = []
    party_type_array  = []
    all_parties       = []
    array = party_record.reject{|s| s.include? '(#'}
    array = array.flatten if array.count == 1
    array.each_with_index do |value, index_no|
      if (value.include? 'Defendant') || (value.include? 'Plaintiff') || (value.include? 'Appellant') || (value.include? 'Appellee') || (value.include?("Petitioner")) || (value.include?("Respondent")) || (value.include? ', Provider')
        party_names, party_types = get_party_details(value)
        party_name_array << party_names
        party_type_array << party_types
      else
        party_name_array << value
      end
    end
    all_parties << {party_name: party_name_array.join(' ').strip.squeeze(' '), party_type: party_type_array.join(' ').strip.squeeze(' ')}
  end

  def get_attorney_address(array)
    total_occurances, total_occurances_indexes = include_with_state?(array)
    return [nil, nil] if total_occurances == 0
    record = array[total_occurances_indexes.first]
    array_address = record.split('       ').reject{|s| s==""}
    party_address_details = array_address.first
    party_city = party_address_details.split(',').first.strip
    party_state = party_address_details.split(',').last.strip
    [party_city, party_state]
  end

  def get_attoney_party_type(array_record)
    party_type_array = []
    record_index = array_record.find_index{|s| (s.include? 'Attorneys for') || (s.include? 'Attorney for') || (s.downcase.include? 'pro se ')}
    return nil if record_index == nil
    record = array_record[record_index].strip
    party_type_array << record.split('       ').reject{|s| s == ""}.last
    array_record[record_index+1..-1].each do |type_record|
      split_array = type_record.split('   ').reject{|s| s == ""}
      if split_array[-1].strip.squeeze(' ') == "and"
        party_type_array << split_array.reverse.join(' ')
      else
        party_type_array << type_record.split('   ').reject{|s| s == ""}.last
      end
    end
    party_type_array.join(' ').strip.squeeze(' ')
  end

  def get_attorney_name(array_record)
    name_array = array_record.select{|s| (s.strip.scan(/\A[A-Z]*\s[A-Z]*.?\s?[A-Z]*,?\s?[A-Z]*\z/) | s.strip.scan(/\A[A-Z]*\s[A-Z]*.?\s?[A-Z]*,?\s?[A-Z]*\sof\z/)).count > 0}
    if name_array.count == 0
      name_array = [array_record[0].strip.split('   ').reject{|s| s == ""}[0]]
    end
    name_array
  end

  def get_party_law_firm(array_record)
    record_array = []
    return array_record[-1].strip if array_record[-1].include? "Attorney General"

    total_occurances, total_occurances_indexes = include_with_state?(array_record)
    if total_occurances != 0
      record_index = total_occurances_indexes[0]
      while record_index > 1
        record = array_record[record_index-1].strip
        if (record.scan(/\A[A-Z]*\s[A-Z]*.?\s?[A-Z]*\s?[A-Z]*\z/) | record.scan(/\A[A-Z]*\s[A-Z]*.?\s?[A-Z]*\s?[A-Z]*\sof\z/)).count == 0
          record_array << record.split('   ').reject{|s| s == ""}[0]
        else
          break
        end
        record_index-=1
      end
    end
    record_array.reverse.join("\n").strip.squeeze(' ')
  end

  def get_all_attorneys(array, case_id, run_id)
    all_parties_attorneys = []
    multiple_records      = []
    previous_index        = 0
    array = array.reject{|s| s.strip == "and"}
    total_occurances, total_occurances_indexes = include_with_state?(array)
    if total_occurances > 1
      (0..total_occurances-1).each do |index_no|
        record_index = total_occurances_indexes[index_no]
        if record_index != nil
          if index_no == total_occurances-1
            multiple_records << array[previous_index..-1]
          else
            multiple_records << array[previous_index..record_index]
          end
          previous_index = record_index+1
        else
          multiple_records << array[previous_index..record_index]
        end
      end
    end

    multiple_records << array if multiple_records.count == 0
    multiple_records.each_with_index do |array_record, array_record_index|
      party_name_array = get_attorney_name(array_record)
      party_law_firm = get_party_law_firm(array_record)
      party_type = get_attoney_party_type(array_record)
      party_city, party_state = get_attorney_address(array_record)
      all_parties_attorneys << {party_name: party_name_array.join("\n").strip.squeeze(' '), party_type: party_type, party_law_firm: party_law_firm, party_city: party_city, party_state: party_state, run_id: run_id}
    end
    all_parties_attorneys
  end

  def insert_party_records(array_hash, data_hash, run_id)
    array_hash.each do |record|
      party_record_hash = data_hash.clone
      party_record_hash[:party_name]      = record[:party_name]
      party_record_hash[:party_type]      = record[:party_type]
      party_record_hash = mark_empty_as_nil(party_record_hash) unless party_record_hash.nil?
      party_record_hash[:md5_hash]        = create_md5_hash(party_record_hash)
      party_record_hash[:run_id]          = run_id
      party_record_hash[:touched_run_id]  = run_id
      party_record_hash[:data_source_url] = @source_url
      @case_party << party_record_hash
    end
    @case_party
  end

  def insert_party_attorney_records(array_hash, case_id, run_id)
    array_hash.each do |record|
      party_record_hash= {}
      party_record_hash[:court_id]        = COURT_ID
      party_record_hash[:case_id]         = case_id
      party_record_hash[:is_lawyer]       = 1
      party_record_hash[:party_name]      = record[:party_name]
      party_record_hash[:party_type]      = record[:party_type]
      party_record_hash[:party_law_firm]  = record[:party_law_firm]
      party_record_hash[:party_city]      = record[:party_city]
      party_record_hash[:party_state]     = record[:party_state]
      party_record_hash = mark_empty_as_nil(party_record_hash) unless party_record_hash.nil?
      party_record_hash[:md5_hash]        = create_md5_hash(party_record_hash)
      party_record_hash[:data_source_url] = @source_url
      party_record_hash[:run_id]          = run_id
      party_record_hash[:touched_run_id]  = run_id
      @case_party_attorny << party_record_hash
    end
  end

  def case_party_split_by_and(party_record, party_data_array)
    if party_record.select{|s|s.strip == "and"}.count > 0
      while party_record.select{|s|s.strip == "and"}.count > 0
        and_index = party_record.find_index{|s| s.strip == 'and'}
        record_1, party_record = party_record[0...and_index], party_record[and_index+1..-1]
        party_data_array << record_1
      end
      party_data_array << party_record
    elsif party_record.select{|s| (s.end_with? 'Appellant,') || (s.end_with? 'Appellant.') || (s.end_with? 'Plaintiffs,') || (s.end_with? 'Plaintiffs.') || (s.end_with? 'Appellees.') || (s.end_with? 'Appellees,') || (s.end_with? ' Appellee.') || (s.end_with? ' Appellee,') || (s.end_with? ' Appellants,') || (s.end_with? ' Appellants.') || (s.end_with? ' Defendant.') || (s.end_with? ' Defendant,')}.count > 1
      index_no = party_record.find_index{|s| (s.end_with? 'Appellant,') || (s.end_with? 'Appellant.') || (s.end_with? 'Plaintiffs,') || (s.end_with? 'Plaintiffs.') || (s.end_with? 'Appellees.') || (s.end_with? 'Appellees,') || (s.end_with? ' Appellee.') || (s.end_with? ' Appellee,') || (s.end_with? ' Appellants,') || (s.end_with? ' Appellants.') || (s.end_with? ' Defendant.') || (s.end_with? ' Defendant,')}
      party_data_array << party_record[0..index_no]
      party_data_array << party_record[index_no+1..-1]
    else
      party_data_array << party_record
    end
    party_data_array
  end

  def case_party(case_id, run_id)
    data_hash = {}
    data_hash[:court_id]          = COURT_ID
    data_hash[:case_id]           = case_id
    data_hash[:is_lawyer]         = 0
    data_hash[:party_law_firm]    = nil
    data_hash[:party_address]     = nil
    data_hash[:party_city]        = nil
    data_hash[:party_state]       = nil
    data_hash[:party_zip]         = nil
    data_hash[:party_description] = nil
    start_ind = find_index("* * * *")

    return [] if start_ind == nil
    party_data = []
    party_data_hash = []

    @document[start_ind + 1..-1].each do |e|
      if (e.include? "* * * *")
        if party_data.select{|s| (s.include? 'Defendant') || (s.include? 'Plaintiffs') || (s.include? 'Appellant') || (s.include? 'Appellee') || (s.include? 'Petitioner') || (s.include? 'Respondent')}.count > 0
          break
        else
          party_data = []
        end
      end
    if party_data.count > 0 && (party_data[-1].strip != 'and') && (party_data[-1].end_with? 'and')
        party_data[-1] = party_data[-1] + ' ' + e.strip
      elsif (!e.include?"* * * *")
        party_data.push(e.strip)
      end
    end

    party_data = party_data.reject{|s| (s.start_with? '-------------') || (s.start_with? '- - - - - -') }
    party_data = party_data.reject{|s| (s.start_with? "##{case_id}") || (s.start_with? "(##{case_id}")}
    if party_data.select{|s| (s.strip.start_with? '#') || (s.strip.start_with? '(#')}.count > 0
      party_data[party_data.find_index{|s| (s.start_with? '#') || (s.start_with? '(#') }] = 'and'
    end

    if party_data.select{|s| s.strip.start_with? 'ARGUED '}
      index_no = party_data.find_index{|s| s.strip.start_with? 'ARGUED '}
      party_data = party_data[0...index_no]
    end

    parties_count = party_data.select{|s| (s.include? 'v.') || (s.include? 'vs.')}.count
    return [] if parties_count == 0
    party_data_array = []
    (0..parties_count).each do |party_no|

      index_no = party_data.find_index('v.') || party_data.find_index('vs.')
      if index_no != nil
        party_record = party_data[0...index_no]
        party_data_array = case_party_split_by_and(party_record, party_data_array)
        party_data = party_data[index_no+1..-1]
      else
        party_data_array = case_party_split_by_and(party_data, party_data_array)
      end
    end

    party_data_array.each do |party_record|
      party_data_hash = get_all_parties(party_record)
      insert_party_records(party_data_hash, data_hash, run_id)
    end
    @case_party = [] if @case_party.nil?
  end

  def include_with_state?(array)
    total_count = 0
    array_indexes = []
    array.each_with_index do |record, index_no|
      if STATES.select{|s| (record.include? s) && (record.include? ',') }.count > 0
        total_count+=1
        array_indexes << index_no
      end
    end
    [total_count, array_indexes]
  end

  def party_attorney_section
    array = []
    start_ind =  @document.rindex{|s| (s.include? "Judge") || (s.include? "ORIGINAL PROCEEDING")}

    if start_ind != nil
      start_ind +=1
      record_index =  @document[start_ind..-1].find_index{|s| (s.strip.scan(/\A[A-Z]*\s[A-Z]*.?\s?[A-Z]*,?\s?[A-Z]*/) | s.strip.scan(/\A[A-Z]*\s[A-Z]*.?\s?[A-Z]*,?\s?[A-Z]*\sof/)).count > 0}
    else
      record_index = nil
    end

    if (start_ind != nil) && (record_index != nil)
      @document[start_ind + record_index ..-1].each do |e|
        break if e.include? "* * * *"
        break if e == nil 
        array.push(e)
      end
    else
      total_records = @document.select{|s| (s.include? "Attorneys for") || (s.include? "Attorney for")  || (s.downcase.include? 'pro se ') || (s.strip == 'Attorney General')}.count
      return [] if total_records == 0

      index_no = @document.find_index{|s| s.strip == '* * * *'}

      if index_no == nil
        array = @document
      else
        section1, section2 = @document[0...index_no], @document[index_no+1..-1]
        array = section1.select{|s| (s.include? "Attorneys for") || (s.include? "Attorney for")  || (s.downcase.include? 'pro se ') || (s.strip == 'Attorney General') }.count > 0 ? section1 : section2
        array.reject!{|s| s.strip.start_with? '(#'}
      end
    end
    array
  end

  def case_party_attorny(case_id, run_id)
    page_no = 1
    party_data = party_attorney_section

    total_records = party_data.select{|s| (s.include? "Attorneys for") || (s.include? "Attorney for")  || (s.downcase.include? 'pro se ') || (s.strip == 'Attorney General')}.count

    while total_records == 0
      fetch_pdf_page(page_no)
      page_no+=1
      break if page_no > 5

      party_data = party_attorney_section
      total_records = party_data.count
    end

    total_records = party_data.select{|s| (s.include? "Attorneys for") || (s.include? "Attorney for")  || (s.downcase.include? 'pro se ') || (s.strip == 'Attorney General') || (s.strip.start_with? 'Aurora County State') }.count

    (0...total_records).each do |record|
      if total_records == 1
        record_data = party_data
      else
        record_index = party_data.find_index{|s| (s.include? "Attorneys for") || (s.include? "Attorney for") || (s.downcase.include? 'pro se')  || (s.strip == 'Attorney General')  || (s.strip.start_with? 'Aurora County State') }

        break if record_index == nil

        if (party_data[record_index].include? 'appellees.')  || (party_data[record_index].strip == 'Attorney General')  || (party_data[record_index].include? 'appellee.') || (party_data[record_index].include? 'appellant.') || (party_data[record_index].include? 'plaintiffs.') || (party_data[record_index].include? 'defendant.') || (party_data[record_index].include? 'appellants.') || (party_data[record_index].downcase.include? 'petitioner.')  || (party_data[record_index].include? 'Aurora County State')
          record_data = party_data[0..record_index]
          party_data = party_data[record_index+1..-1]
        else
          index_temp = party_data[record_index+1..-1].find_index{|s| (s.end_with? '.') || (s.include? 'appellees.') || (s.include? 'appellee.') || (s.include? 'appellant.')} || 0
          if index_temp.to_i <=4
            record_data = party_data[0..record_index+1+index_temp]
            party_data = party_data[record_index+2+index_temp..-1]
          else
            index_temp = party_data[record_index+1..-1].find_index{|s| (s.include? '.') || (s.include? 'appellees.') || (s.include? 'appellee.') || (s.include? 'appellant.')} || 0
            record_data = party_data[0..record_index+1+index_temp]
            party_data = party_data[record_index+2+index_temp..-1]
          end
        end
      end
      all_parties_attorneys = get_all_attorneys(record_data, case_id, run_id)
      insert_party_attorney_records(all_parties_attorneys, case_id, run_id)
      break if party_data == nil || party_data.count == 0

    end
  end

  def disposition_or_status
    start_ind = find_index("FILED",true)
    data_array = []
    while true
      if (!@reverse_doc[start_ind].include? '* * * *') && (!@reverse_doc[start_ind].include? '-------') && (!@reverse_doc[start_ind].include? '.')
        data_array << @reverse_doc[start_ind]
        break if (@reverse_doc[start_ind].include? 'ARGUED') || (@reverse_doc[start_ind].include? 'CONSIDERED')
        start_ind+=1
      else
        break
      end
    end

    status = data_array.reverse.map{|e| e.strip.squeeze(' ')}.join(" ") rescue nil

    unless status.nil?
      year = status.scan(/\d+/)[1]
      status = "#{status.split(year).first}#{year}"
    end
    status
  end

  def get_judge_name
    page_no = 0

    while page_no < 4
      ind = find_index("HONORABLE")
      if ind.nil?
        ind = find_index("Judge")
        ind -=1 if ind != nil
      end

      if ind != nil
        judge_name = @document[ind].strip.gsub("THE HONORABLE","")
        fetch_pdf_page(0)
        return judge_name
      else
        page_no+=1
        fetch_pdf_page(page_no)
      end
    end
    fetch_pdf_page(0)
    nil
  end

  def case_info(case_id, date, title, run_id)
    data_hash = {}
    data_hash[:court_id]              = COURT_ID
    data_hash[:case_id]               = case_id
    data_hash[:case_name]             = title
    data_hash[:case_filed_date]       = Date.strptime(date, '%m/%d/%Y')
    data_hash[:case_type]             = nil
    data_hash[:case_description]      = nil
    data_hash[:disposition_or_status] = disposition_or_status
    data_hash[:status_as_of_date]     = nil
    data_hash[:judge_name]            = get_judge_name.squish rescue nil
    data_hash[:lower_court_id]        = nil
    data_hash[:lower_case_id]         = nil
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    @info_md5_hash                    = create_md5_hash(data_hash)
    data_hash[:data_source_url]       = @source_url
    data_hash[:touched_run_id]        = run_id
    data_hash[:md5_hash]              = @info_md5_hash
    data_hash[:run_id]                = run_id
    @case_info << data_hash
  end

  def case_consolidations(case_id, run_id)
    consolidations_array = @document[0].split('#').reject{|s| s.strip ==""}
    consolidations_array.each do |consolidation_value|
      consolidation_value = consolidation_value.gsub(', ', '') if consolidation_value.end_with? ', '
      next if consolidation_value == case_id
      data_hash = {}
      data_hash[:court_id]                      = COURT_ID
      data_hash[:case_id]                       = case_id
      data_hash[:consolidated_case_id]          = consolidation_value
      data_hash[:consolidated_case_name]        = nil
      data_hash[:consolidated_case_filled_date] = nil
      data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
      data_hash[:md5_hash]                      = create_md5_hash(data_hash)
      data_hash[:data_source_url]               = @source_url
      data_hash[:touched_run_id]                = run_id
      data_hash[:run_id]                        = run_id
      @case_consolidations.push(data_hash)
    end
  end

  def case_pdfs_on_aws(case_id, pdf_link, run_id, s3, page)
    data_hash = {}
    data_hash[:court_id]         = COURT_ID
    data_hash[:case_id]          = case_id
    data_hash[:source_type]      = 'info'
    key = 'us_courts_expansion_' + COURT_ID.to_s + '_' + case_id.to_s + '_' + pdf_link.split("/").last
    data_hash[:aws_link]         = upload_file_to_aws(key, s3, page)
    data_hash[:source_link]      = DOMAIN + pdf_link
    @aws_md5_hash                = create_md5_hash(data_hash)
    data_hash[:data_source_url]  = @source_url
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    data_hash[:md5_hash]         = @aws_md5_hash
    data_hash[:run_id]           = run_id
    data_hash[:touched_run_id]   = run_id
    @case_pdfs_on_aws.push(data_hash)
  end

  def case_relations_info_pdf
    data_hash = {}
    data_hash[:court_id]            = COURT_ID
    data_hash[:case_info_md5]       = @info_md5_hash
    data_hash[:case_pdf_on_aws_md5] = @aws_md5_hash
    @case_relations_info_pdf.push(data_hash)
  end
  
  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end
 
  def find_index(string, reverse_doc_flag = false, doc = @document)
    doc = @reverse_doc if reverse_doc_flag
    check = doc.select{|e| e.include? string}
    doc.index check[0]
  end
end
