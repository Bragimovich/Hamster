# frozen_string_literal" => true
class Parser < Hamster::Parser

  COURT_ID = 81
  MAIN_URL = "https://publicrecords.alameda.courts.ca.gov"
  URL = "https://publicrecords.alameda.courts.ca.gov/PRS/Case/CaseDetails/"

  def captha_token(response)
    doc = parsing(response)
    doc.css("#recaptcha-token")[0]['value']
  end

  def json_parsing(response)
    JSON.parse(response)
  end

  def locations(page)
    page.css("#SelectedCourtLocation").css("option").map{|e| [e.text, e["value"]]}
  end

  def case_types(page)
    page.css("#SelectedCaseSubTypeId").css("option").map{|e| [e.text, e["value"]]}
  end

  def parsing(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def fetch_pdf_links(response)
    html = parsing(response)
    html.css('#GridID tbody tr').map { |e| "https://publicrecords.alameda.courts.ca.gov" + e.css('a')[0]['href'] rescue nil }.reject { |e| e.nil? }
  end

  def parse_files(case_info_data, case_activity_data, case_party_data, run_id, encrypted_num)
    case_info_hash, md5_hash = case_info(case_info_data, run_id, encrypted_num)
    case_activities_array    = (case_activity_data.nil?) ? nil : case_activities(case_activity_data, case_info_hash[:case_id], run_id, encrypted_num)
    case_party_array         = (case_activity_data.nil?) ? nil : case_party(case_party_data, case_info_hash[:case_id], run_id, encrypted_num)
    [case_info_hash, md5_hash, case_activities_array, case_party_array]
  end

  def pdfs_on_aws(activity, pdf_name)
    data_hash = {}
    data_hash[:court_id]    = activity[:court_id]
    data_hash[:case_id]     = activity[:case_id]
    if pdf_name == 'info'
      data_hash[:aws_html_link] = "us_courts_expansion_#{data_hash[:court_id].to_s}_#{data_hash[:case_id].to_s}_info_#{pdf_name}.html"
      data_hash[:source_link] = activity[:data_source_url]
      data_hash[:aws_link] = nil
      data_hash[:source_type] = 'info'
    else
      data_hash[:aws_html_link] = nil
      data_hash[:aws_link]    = "us_courts_expansion_#{data_hash[:court_id].to_s}_#{data_hash[:case_id].to_s}_activity_#{pdf_name}.pdf"
      data_hash[:source_link] = activity[:activity_pdf]
      data_hash[:source_type] = 'activity'
    end
    data_hash[:md5_hash]    = create_md5_hash(data_hash)
    data_hash[:data_source_url] = activity[:data_source_url]
    data_hash[:run_id]          = activity[:run_id]
    data_hash[:touched_run_id]  = activity[:touched_run_id]
    data_hash
  end

  def aws_upload(pdf_aws_hash, pdf, s3, pdf_hash_array, activity_md5, relations_array, run_id)
    pdf_aws_hash[:aws_link] = upload_file_to_aws(pdf_aws_hash, pdf, s3, 'pdf')
    relations_hash = relations_activity_pdf(activity_md5, pdf_aws_hash[:md5_hash], run_id)
    pdf_hash_array << pdf_aws_hash
    relations_array << relations_hash
    [pdf_hash_array, relations_array]
  end

  def aws_html_upload(html_aws_hash, html, s3, info_md5, run_id)
    html_aws_hash[:aws_html_link] = upload_file_to_aws(html_aws_hash, html, s3, 'info')
    relations_hash = relations_info_pdf(info_md5, html_aws_hash[:md5_hash], run_id)
    [html_aws_hash, relations_hash]
  end

  private

  def relations_info_pdf(info_md5, aws_md5, run_id)
    data_hash = {}
    data_hash[:court_id]            = COURT_ID
    data_hash[:case_info_md5]       = info_md5
    data_hash[:case_pdf_on_aws_md5] = aws_md5
    data_hash[:md5_hash]            = create_md5_hash(data_hash)
    data_hash[:run_id]              = run_id
    data_hash[:touched_run_id]      = run_id
    data_hash
  end

  def upload_file_to_aws(aws_data, pdf, s3, type)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    return aws_url + aws_data[:aws_link] unless s3.find_files_in_s3(aws_data[:aws_link]).empty? if type == 'pdf'

    return aws_url + aws_data[:aws_html_link] unless s3.find_files_in_s3(aws_data[:aws_html_link]).empty? if type == 'info'

    key     = aws_data[:aws_link] if type == 'pdf'
    key     = aws_data[:aws_html_link] if type == 'info'
    s3.put_file(pdf, key, metadata={})
  end

  def relations_activity_pdf(activity_md5, pdf_md5, run_id)
    data_hash = {}
    data_hash[:court_id]            = COURT_ID
    data_hash[:case_activities_md5] = activity_md5
    data_hash[:case_pdf_on_aws_md5] = pdf_md5 
    data_hash[:md5_hash]            = create_md5_hash(data_hash)
    data_hash[:run_id]              = run_id
    data_hash[:touched_run_id]      = run_id

    data_hash
  end

  def case_info(case_info_data, run_id, encrypted_num)
    parsed_data = parsing(case_info_data)
    case_summary = parsed_data.css("table")
    data_hash = {}
    data_hash[:court_id]              = COURT_ID
    data_hash[:case_id]               = search_value(case_summary, "Case Number")
    data_hash[:case_name]             = search_value(case_summary, "Title")
    case_type                         = search_value(case_summary, "Case Type")
    case_subtype                      = search_value(case_summary, "Case Subtype")
    data_hash[:case_type]             = "#{case_type}\; #{case_subtype}"
    date                              = search_value(case_summary, "Filing Date")
    data_hash[:case_filed_date]       = date_formation(date)
    data_hash[:case_description]      = search_value(case_summary, "Filing Location")
    data_hash[:md5_hash]              = create_md5_hash(data_hash)
    data_hash[:data_source_url]       = URL + encrypted_num
    mark_empty_as_nil(data_hash)
    data_hash[:run_id]                = run_id
    data_hash[:touched_run_id]        = run_id
    [data_hash, data_hash[:md5_hash]]
  end

  def case_party(case_party, case_id, run_id, encrypted_num)
    return [] if case_party.nil?
    data = parsing(case_party)
    data_array = []
    rows = data.css("tr")
    rows[1..].each do |row|
      data_hash = {}
      data = row.css("td")
      data_hash[:court_id]        = COURT_ID
      data_hash[:case_id]         = case_id
      data_hash[:party_name]      = activities_value(data[1])
      data_hash[:party_type]      = activities_value(data[0])
      data_hash[:is_lawyer]       = (data_hash[:party_type] == "Attorney") ? 1 : 0
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:data_source_url] = URL + encrypted_num
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_array << data_hash
    end
    data_array
  end

  def case_activities(case_activities, case_id, run_id, encrypted_num)
    activities_array = []
    parsed_data = parsing(case_activities)
    activities = parsed_data.css("tr")
    activities[1..].each do |activity|
      data_hash = {}
      activity_values             = activity.css("td")
      data_hash[:court_id]        = COURT_ID
      data_hash[:case_id]         = case_id
      date                        = activities_value(activity_values[0])
      data_hash[:activity_date]   = date_formation(date)
      data_hash[:activity_decs]   = activities_value(activity_values[1])
      pdf_link                    = (activity_values[5].css("a").empty?)? nil : activity_values[5].css("a")[0]['href']
      data_hash[:activity_pdf]    = (pdf_link.nil?) ? nil : MAIN_URL + pdf_link
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:data_source_url] = URL + encrypted_num
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      activities_array << data_hash
    end
    activities_array
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| (value.to_s == " ") || (value == 'null') || (value == '') ? nil : value }
  end

  def activities_value(value)
    value.text.squish
  end

  def date_formation(date)
    Date.strptime(date, "%m/%d/%Y").to_date rescue nil
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def search_value(doc, key)
    tr = doc.css("tr")
    value = tr.select {|e| e.text.strip.squish.start_with? key}
    text = (value[0].text.nil?) ? nil : value[0].text.squish
    if key == "Filing Location"
      key_value = (text.nil?) ? nil : text.squish
    else
      key_value = (text.nil?) ? nil : text.gsub("#{key}:",'').squish
    end
    key_value
  end

end
