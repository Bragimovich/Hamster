class Parser < Hamster::Parser

  def post_request_parameters(html)
    data = nokogiri_converter(html)
    eventvalidation    = data.css('#__EVENTVALIDATION')[0]['value']
    viewstate          = data.css('#__VIEWSTATE')[0]['value']
    viewstategenerator = data.css('#__VIEWSTATEGENERATOR')[0]['value']
    [eventvalidation, viewstate, viewstategenerator]
  end

  def fetch_case_ids(html)
    data = nokogiri_converter(html)
    ids_array   = data.css('#grdSearchResult tr')[1..].map { |e| e['onclick'].split("'")[1] }
    total_pages = data.css('#lblTopPager input')[0]['value'].split('of').last
    [ids_array, total_pages.squish.to_i]
  end

  def fetch_url(html)
    data = nokogiri_converter(html)
    id = data.css('#case-details-post form')[0]['action'].split('=').last rescue nil
    "https://pch.tncourts.gov/CaseDetails.aspx?id=#{id}&Number=True"
  end

  def fetch_page_info(html, court_id, run_id)
    data = nokogiri_converter(html)
    id = data.css('#case-details-post form')[0]['action'].split('=').last rescue nil
    return [] if id.nil?

    url = "https://pch.tncourts.gov/CaseDetails.aspx?id=#{id}&Number=True"

    info_hash             = us_case_info(data, url, court_id, run_id)
    party_array           = us_case_party(data, url, court_id, run_id)
    actvities_array       = us_case_activities(data, url, court_id, run_id)
    additional_info_array = us_case_additional_info(data, url, court_id, run_id)
    [info_hash, party_array, actvities_array, additional_info_array]
  end

  def fetch_pdf_links(html, alread_downloaded_pdfs_count)
    data = nokogiri_converter(html)
    links_array = []
    data.css('#case-history tbody tr').each do |row|
      unless row.css('td').last.text.strip.empty?
        links = row.css('td').last.children.map { |a| a['href'].split("'")[1] rescue '' }.reject(&:empty?)
        links_array += links
      end
    end
    new_pages = links_array.count - alread_downloaded_pdfs_count
    links_array[0...new_pages]
  end

  def find_pdf_names(html)
    pdf_names_array = []
    data = nokogiri_converter(html)
    data.css('#case-history tbody tr').each do |row|
      unless (row.css('td').last.text.strip.empty?)
        row.css('td').last.css('a').each do |a_tag|
          next if a_tag['key'].nil?

          pdf_hash = {}
          pdf_hash[:key]  = a_tag['href'].split("'")[1]
          pdf_hash[:name] = a_tag['key']
          pdf_names_array << pdf_hash
        end
      end
    end
    pdf_names_array
  end

  def update_html(html, pdfs_names_array)
    data = nokogiri_converter(html)
    all_activities_links = data.css('#case-history tbody tr a')
    pdfs_names_array.each do |pdf_record|
      matched_record = all_activities_links.select { |s| s['href'].split("'")[1] == pdf_record[:key] }
      matched_record[0]['key'] = pdf_record[:name]
    end
    data.to_s
  end

  def activities_pdfs_on_aws(court_id, case_id, pdf_name, url, type, run_id)
    data_hash_pdf = {}
    data_hash_pdf[:court_id]        = court_id
    data_hash_pdf[:case_id]         = case_id
    data_hash_pdf[:source_type]     = type
    data_hash_pdf[:aws_html_link]   = data_hash_pdf[:aws_link] = nil
    if type == 'info'
      data_hash_pdf[:aws_html_link] = "us_courts_expansion_#{court_id.to_s}_#{case_id.to_s}_#{pdf_name}"
    else
      data_hash_pdf[:aws_link]      = "us_courts_expansion_#{court_id.to_s}_#{case_id.to_s}_#{type.to_s}_#{pdf_name}"
    end
    data_hash_pdf[:source_link]     = url
    data_hash_pdf[:md5_hash]        = create_md5_hash(data_hash_pdf)
    data_hash_pdf[:run_id]          = run_id
    data_hash_pdf[:touched_run_id]  = run_id
    mark_null(data_hash_pdf)
  end

  def case_relations_activity_pdf(pdf_md5, activity_pdf, court_id)
    case_relations_activity = {}
    case_relations_activity[:case_activities_md5] = activity_pdf
    case_relations_activity[:case_pdf_on_aws_md5] = pdf_md5
    case_relations_activity[:court_id]            = court_id
    case_relations_activity
  end

  def case_relations_info_pdf(pdf_md5, activity_pdf, court_id)
    case_relations_activity = {}
    case_relations_activity[:case_info_md5]       = activity_pdf
    case_relations_activity[:case_pdf_on_aws_md5] = pdf_md5
    case_relations_activity[:court_id]            = court_id
    case_relations_activity
  end

  private

  def nokogiri_converter(html)
    Nokogiri::HTML(html.force_encoding('utf-8'))
  end

  def us_case_additional_info(data, url, court_id, run_id)
    additional_info_array = []
    case_id                    = data.css('.case-number').text rescue nil
    lower_case_id              = data.css('#case-overview2 tr td')[-1].text
    additional_lower_case_id   = data.css('#case-overview2 tr td')[0].text
    lower_judge_name           = data.css('#case-overview2 tr td')[-2].text
    lower_court_name           = data.css('#case-overview2 tr td')[-3].text
    lower_case_id              = lower_case_id.split(',')
    lower_case_id << additional_lower_case_id
    lower_case_id.each_with_index do |lower_id, index|
      data_hash = {}
      data_hash[:court_id]         = court_id
      data_hash[:case_id]          = case_id
      data_hash[:lower_court_name] = index == lower_case_id.count-1 ? nil : lower_court_name
      data_hash[:lower_case_id]    = lower_id
      data_hash[:lower_judge_name] = index == lower_case_id.count-1 ? nil : lower_judge_name
      data_hash[:data_source_url]  = url
      data_hash[:md5_hash]         = create_md5_hash(data_hash)
      data_hash[:run_id]           = run_id
      data_hash[:touched_run_id]           = run_id
      data_hash = mark_null(data_hash)
      unless (lower_id.empty? || lower_id.nil?)
        additional_info_array << data_hash
      end
    end
    additional_info_array
  end

  def us_case_activities(data, url, court_id, run_id)
    activities_hash_array = []
    case_id               = data.css('.case-number').text rescue nil
    data                  = data.css('#case-history') rescue nil
    if data
      activity_data = data.css('table tbody tr')
      activity_data.each do |row|
        data_hash = {}
        date      = row.css('td')[0].text rescue nil
        data_hash[:court_id]        = court_id
        data_hash[:case_id]         = case_id
        data_hash[:activity_date]   = DateTime.strptime(date, '%m/%d/%Y').to_date rescue nil
        data_hash[:activity_desc]   = row.css('td')[1].text + "; " + row.css("td")[2].text.squish rescue nil
        data_hash[:activity_type]   = data_hash[:activity_desc].split("-")[0] rescue nil
        data_hash[:data_source_url] = url
        data_hash[:md5_hash]        = create_md5_hash(data_hash)
        data_hash[:run_id]          = run_id
        data_hash[:touched_run_id]  = run_id
        activities_hash_array <<  mark_null(data_hash)
      end
    end
    activities_hash_array
  end

  def us_case_party(data, url, court_id, run_id)
    lawyers_hash_array = []
    case_id = data.css('.case-number').text rescue nil
    data.css('#case-parties tr')[1..-1].each do |party|
      first_party_name   = party.css('td')[0].text
      party_type         = party.css('td')[1].text
      second_party_name  = party.css('td')[2].text
      first_party_hash   = create_party_hash(first_party_name, party_type, url, court_id, case_id , false, run_id)
      second_party_hash  = create_party_hash(second_party_name, party_type, url, court_id, case_id , true, run_id)
      lawyers_hash_array << first_party_hash
      lawyers_hash_array << second_party_hash
    end
    lawyers_hash_array
  end

  def us_case_info(data, url, court_id, run_id)
    data_hash = {}
    data_hash[:court_id]                = court_id
    data_hash[:case_id]                 = data.css('.case-number').text rescue nil
    data_hash[:case_name]               = data.css('.case-title').text rescue nil
    data_hash[:lower_case_id]           = data.css('#case-overview2 table tbody tr td')[-1].text.split(',')[0] rescue nil
    data                                = data.css('#case-milestones') rescue nil
    unless data.nil?
      case_filed_date                   = get_values(data, 'Appeal Filed')
      case_filed_date                   = (case_filed_date.nil?) ? get_values(data, 'Application Filed') : case_filed_date
      data_hash[:case_filed_date]       = DateTime.strptime(case_filed_date , '%m/%d/%Y').to_date rescue nil
      data_hash[:case_type]             = data_hash[:case_id].split("-").last
      data_hash[:status_as_of_date]     = get_values(data, 'Closed Date')
      data_hash[:disposition_or_status] = ((data_hash[:disposition_or_status]).nil? || (data_hash[:disposition_or_status]).empty? )? nil : "Closed"
    end
    data_hash[:data_source_url]         = url
    data_hash[:md5_hash]                = create_md5_hash(data_hash)
    data_hash[:run_id]                  = run_id
    data_hash[:touched_run_id]          = run_id
    mark_null(data_hash)
  end

  def get_values(data, search_text)
    values = data.css('td').select { |e| e.text.include? "#{search_text}" }
    return values[0].next_element.text.strip rescue nil unless values.empty?
  end

  def create_party_hash(party, party_type, url, court_id, case_id, lawyer, run_id)
    data_hash = {}
    data_hash[:court_id]            = court_id
    data_hash[:case_id]             = case_id
    data_hash[:is_lawyer]           = lawyer ? 1 : 0
    data_hash[:party_name]          = party.squish rescue nil
    data_hash[:party_type]          = party_type.squish rescue nil
    data_hash[:data_source_url]     = url
    data_hash[:md5_hash]            = create_md5_hash(data_hash)
    data_hash[:run_id]              = run_id
    data_hash[:touched_run_id]      = run_id
    mark_null(data_hash)
  end

  def mark_null(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? ? nil : value }
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
