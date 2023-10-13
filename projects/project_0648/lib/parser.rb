# frozen_string_literal: true

class Parser < Hamster::Parser
  COURT_ID = '92'
  DOMAIN = 'https://myeclerk.myorangeclerk.com'
  SOURCE_URL = 'https://myeclerk.myorangeclerk.com/Cases/Search'
  AWS_PREFIX = 'https://court-cases-activities.s3.amazonaws.com'

  def search_google_key(page)
    key = page.css('.g-recaptcha').attr("data-sitekey").text
    token = page.css("input[name='__RequestVerificationToken']").attr("value").text
    { key: key, token: token }
  end

  def parse_html(body)
    Nokogiri::HTML(body)
  end

  def get_links(page)
    links = page.css('a.caseLink').map{|e| DOMAIN + e['href']}
  end

  def get_case_type(page)
    page.css('#ct option').map {|e| e.attr('value').to_s}
  end

  def get_case_id_pdf_files(page)
    case_id = page.css('#caseDetails div').first.text.split(':').first.gsub('Print','').squish
    pdf_array =  page.css('#chargeDetailsCollapse, #docketData').css('tbody tr td.cdDocLink a').map{|e| DOMAIN + e['href']} rescue []
    [case_id, pdf_array]
  end

  def main_data_parser(page, run_id)
    data_hash = {}
    case_id = page.css('#caseDetails div').first.text.split(':').first.gsub('Print','').squish
    info_array = info(page, run_id, case_id)
    party_array = party(page, run_id, case_id)
    activity_array = activities(page, run_id, case_id)
    aws_pdf_array = aws_pdfs(activity_array, run_id, case_id)
    activity_pdf_array = activity_pdf_relation(activity_array, aws_pdf_array, run_id)
    data_hash = {
      'info' => info_array,
      'party' => party_array,
      'activity' => activity_array,
      'aws_pdf' => aws_pdf_array,
      'activity_pdf_relation' => activity_pdf_array
    }
  end

  private 
  
  def info(page, run_id, case_id)
    data_array =[]
    data_hash = {}
    data_hash['case_id'] = case_id
    data_hash['court_id'] = COURT_ID
    case_details = page.css('#caseDetails div').first.text.split(':')
    data_hash['case_name'] = case_details.last.strip
    case_header = page.css('div#headerCollapse').first
    filed_date = find_case_header('Date Filed:', case_header)
    data_hash['case_filed_date'] = DateTime.strptime(filed_date,"%m/%d/%Y").to_date.to_s
    data_hash['case_description'] = get_case_description(case_header)
    data_hash['case_type'] = find_case_header('Case Type:', case_header)
    data_hash['disposition_or_status'] = nil # need to check more examples
    data_hash['status_as_of_date'] = find_case_header('Status:', case_header)
    data_hash['judge_name'] = find_case_header('Judge:', case_header)
    data_hash['data_source_url']   = SOURCE_URL
    data_hash = mark_empty_as_nil(data_hash)
    data_hash['md5_hash'] = create_md5_hash(data_hash)
    data_hash['run_id'] = run_id
    data_hash['touched_run_id'] = run_id
    data_array.push(data_hash)
    data_array
  end
  
  def party(page, run_id, case_id)
    parties =  page.css('#partiesCollapse tbody tr')
    parties_header =  page.css('#partiesCollapse thead tr')
    header_hash = {}
    parties_header.each do |header|
      header_row = header.css("th")
      header_row.each_with_index do |column, index|
        header_hash['header_name'] = index if column.text.downcase.include?("name") 
        header_hash['header_type'] = index if column.text.downcase.include?("type") 
        header_hash['header_dob'] = index if column.text.downcase.include?("dob") 
        header_hash['header_attorney'] = index if column.text.downcase.include?("attorney") 
        header_hash['header_attr_phone'] = index if column.text.downcase.include?("phone") 
        header_hash
      end
    end
    data_array = []
    parties.each do |party|
      party_row = party.css("td")
      party_hash = {}
      party_hash['court_id'] = COURT_ID
      party_hash['case_id'] = case_id
      party_hash['party_name'] = header_hash['header_name'] ? party_row[header_hash['header_name']].text.strip.gsub(/ +/, " ") : ""
      party_hash['party_type'] = header_hash['header_type'] ? party_row[header_hash['header_type']].text.strip : ""
      party_hash['is_lawyer'] = 0
      party_dob = header_hash['header_dob'] ? party_row[header_hash['header_dob']].text.strip : "" 
      party_hash['party_description'] = !party_dob.empty? ? "DOB: #{party_dob}" : ""
      party_hash['data_source_url']   = SOURCE_URL
      party_hash = mark_empty_as_nil(party_hash)
      lawyer_hash = {}
      lawyer_name = header_hash['header_attorney'] ? party_row[header_hash['header_attorney']].text.strip : ""
      if !lawyer_name.empty?
        lawyer_hash = party_hash.clone
        lawyer_hash['is_lawyer'] = 1
        lawyer_hash['party_name'] = lawyer_name
        lawyer_hash['md5_hash'] = create_md5_hash(lawyer_hash)
        lawyer_hash['run_id'] = run_id
        lawyer_hash['touched_run_id'] = run_id
        data_array.push(lawyer_hash)
      end
      party_hash['md5_hash'] = create_md5_hash(party_hash)
      party_hash['touched_run_id'] = run_id
      party_hash['run_id'] = run_id
      data_array.push(party_hash)
    end
    data_array
  end

  def activities(page, run_id, case_id)
    data_array = []
    activities =  page.css('#chargeDetailsCollapse, #docketData').css('tbody tr')
    activities.each do |activity|
      data_hash = {}
      data_hash['court_id'] = COURT_ID
      data_hash['case_id'] = case_id
      data_hash['activity_date'] = DateTime.strptime(activity.css("td").first.text.strip,"%m/%d/%Y").to_date.to_s 
      activity_desc = activity.css("td")[1]
      hidden_p = activity_desc.css('p[hidden="hidden"]').remove
      data_hash['activity_decs'] = activity_desc.text.squish
      data_hash['activity_type'] = nil
      pdf_anker = activity.css('td.cdDocLink a')
      data_hash['activity_pdf'] = pdf_anker.empty? ? nil : DOMAIN + pdf_anker.first['href']
      data_hash['data_source_url']   = SOURCE_URL
      data_hash = mark_empty_as_nil(data_hash)
      data_hash['md5_hash'] = create_md5_hash(data_hash)
      data_hash['run_id'] = run_id
      data_hash['touched_run_id'] = run_id
      data_array.push(data_hash)
    end
    data_array
  end
  
  def aws_pdfs(activity_array, run_id, case_id)
    data_array = []
    pdf_index = 0
    activity_array.each_with_index do |e, ind|
      pdf_link = e['activity_pdf'] 
      next if pdf_link.nil?
      data_hash = {}
      data_hash['case_id'] = case_id
      data_hash['court_id'] = COURT_ID
      data_hash['source_type'] = "activities"
      file_name = pdf_index
      data_hash['aws_link'] = "#{AWS_PREFIX}/us_courts/#{COURT_ID}/#{case_id}/#{file_name}.pdf"
      data_hash['source_link'] = pdf_link
      data_hash['data_source_url']   = SOURCE_URL
      data_hash = mark_empty_as_nil(data_hash)
      data_hash['md5_hash'] = create_md5_hash(data_hash)
      data_hash['run_id'] = run_id
      data_hash['touched_run_id'] = run_id
      data_array.push(data_hash)
      pdf_index += 1
    end
    data_array
  end

  def activity_pdf_relation(activity_array, aws_pdf_array, run_id)
    data_array = []
    pdf_index = 0
    activity_array.each_with_index do |e, ind|
      pdf_link = e['activity_pdf'] 
      next if pdf_link.nil?
      data_hash = {}
      data_hash["case_activities_md5"] = e['md5_hash']
      data_hash["case_pdf_on_aws_md5"] = aws_pdf_array[pdf_index]['md5_hash']
      data_hash = mark_empty_as_nil(data_hash)
      data_hash['run_id'] = run_id
      data_hash['touched_run_id'] = run_id
      data_array.push(data_hash)
      pdf_index += 1
    end
    data_array
  end

  def find_case_header(key, header)
    header.css('div.row').find{|e| e.css('div').first.text.strip == key}.css('div').last.text
  end

  def get_case_description(header)
    exclude_keys = ['Date Filed:','Case Type:','Status:','Judge:']
    description_kyes = header.css('div.row').reject{ |e| exclude_keys.include? e.css('div').first.text.strip }
    description_kyes.reject{|e| e.text.split(':').last.strip == ''}.map{|e| e.css('div').map{|e| e.text.strip}.join(' ')}.join("\n")
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end
end
