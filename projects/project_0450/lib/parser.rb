class Parser < Hamster::Parser

  def get_parsed_object(html)
    Nokogiri::HTML(html.force_encoding("utf-8"))
  end

  def get_token(page, tag)
    page.css("form[name=#{tag}]").first.css('input').select{|e| !e['name'].nil? and e['name'].include? '.TOKEN'}.first['value']
  end

  def get_total_records(page)
    page.css('form[name="caseNameForm"]').first.css('input').select{|e| !e['name'].nil? and e['name'].include? 'totalRecords'}.first['value']
  end

  def get_record_rows(page,cookie,token,count)
    (page.css('table.table-striped tr')[9].nil?) ?  nil : page.css('table.table-striped tr')[9].css('tr')
  end

  def get_javascript(row)
    row.css('a')[0]['href'].split(':submitform(').last.split("')").first.split(',')
  end

  def check_next(page)
    page.css('table.table-striped tr').last.text rescue ""
  end

  def get_next_page_body(html, page)
    doc = get_parsed_object(html)
    parameters = doc.css('form').select {|a| a.css('input')[0]['type'] == 'hidden' rescue ""}[3].css('input').map{|a|a['value'] rescue ""} rescue ["","","","","","","","","","",""]
    "org.apache.struts.taglib.html.TOKEN=#{parameters[0]}&caseNumber=#{parameters[1]}&agencyCode=#{parameters[2]}&agencyDescription=#{parameters[3].gsub(' ', '+')}&amountDue=#{parameters[4]}&pageNo=#{(parameters[5].to_i)+1}&pageSize=#{parameters[6]}&startRecord=#{parameters[7]}&totalRecords=#{parameters[8]}&isPagingClick=true&originalAmt=&restitution=&sel_pageno_1=#{page}&sel_pageno_2=#{page-1}"
  end

  def get_activities_pages(html)
    doc = get_parsed_object(html)
    doc.css('table.table-striped')[-2].css('tr').last.css('option').last.text rescue 0
  end

  def get_case_activities(html, run_id)
    page = get_parsed_object(html)
    case_id, case_name, case_filed_date = @basic_details
    table = page.css('table.table-striped')[-2].css('tr').select{|a| (a.css('td')[0]['class'] == 'evenrow') || (a.css('td')[0]['class'] == 'oddrow')}  rescue []
    activities_array = []
    table.each do |row|
      activity_date = row.css('td')[0].text.squish
      activity_date = DateTime.strptime(activity_date, '%m-%d-%Y').to_date rescue nil
      data_hash = {
        case_id: case_id,
        court_id: 75,
        activity_date: activity_date,
        activity_desc: row.css('td')[2].text.squish,
        activity_type: row.css('td')[2].text.squish.split('-').first
      }
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      activities_array << data_hash
    end
    activities_array
  end

  def get_aws_uploads(page, s3, run_id)
    case_id, case_name, case_filed_date = @basic_details
    key = "us_courts/75/#{case_id}_info.html"
    data_hash = {
      case_id: case_id,
      court_id: 75,
      aws_link: upload_on_aws(s3, page, key)
    }
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash
  end

  def prepare_info_hash(html, run_id)
    page = get_parsed_object(html)
    table = page.css('div.panel-body table.table-bordered tr')
    return {} if table.empty?
    case_id, case_name, case_filed_date = get_basic_info(table)
    case_description = table.css('table.table-bordered').css('tr')[1].css('td')[1].text.squish rescue nil
    case_filed_date = DateTime.strptime(case_filed_date, '%m-%d-%Y').to_date rescue nil
    status_as_of_date = table[4].css('td')[0].text.squish
    data_hash = {
      case_id: case_id,
      court_id: 75,
      case_name: case_name,
      case_filed_date: case_filed_date,
      case_description: case_description,
      status_as_of_date: status_as_of_date
    }
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash
  end
  
  def get_case_info(cases_page, javascript_parameters, page_no)
    page = get_parsed_object(cases_page)
    full_last_name = javascript_parameters[3].gsub("'","").squish
    data_array = []
    title = page.css('table.table-bordered')[-2].css('td').map{ |a| a.text.squish.downcase.gsub(" ","_")} rescue nil
    return [] if title.nil?
    page.css('table.table-bordered').last.css('tr').each do |row|
      values = row.css('td').map{ |a| a.text.squish}
      data_hash = {}
      title.each_with_index do |key, ind|
        data_hash[:"#{key}"] = values[ind]
      end
      data_hash[:full_last_name] = full_last_name
      data_hash[:search_letter] = full_last_name.first
      data_hash[:page_no] = page_no
      data_array << data_hash
    end
    data_array
  end

  def get_party_info(party_records, run_id)
    parties_array = []
    party_records.each do |party|
      if party[:title].include? party[:full_last_name]
        name = party[:title].split(' -VS- ').select{|a| a.include? party[:full_last_name]}.first
      else
        name = party[:title].split(' -VS- ').reject{|a| a.include? party[:full_last_name]}.first
      end
      data_hash = {
        case_id: party[:case_number],
        court_id: 75,
        party_name: name,
        party_type: party[:role]
      }
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      parties_array << data_hash
    end
    parties_array
  end

  private

  def get_basic_info(page)
    case_number = page[0].css('td')[0].text.squish
    case_name = page[2].css('td')[0].text.squish
    case_filed_date = page[1].css('td')[0].text.squish
    @basic_details = [case_number, case_name, case_filed_date]
    @basic_details
  end

  def upload_on_aws(s3, file, key)
    url = 'https://court-cases-activities.s3.amazonaws.com/'
    return "#{url}#{key}" unless s3.find_files_in_s3(key).empty?
    s3.put_file(file, key, metadata={})
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end
end
