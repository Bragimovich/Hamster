class Parser

  def find_ids(data)
    data = JSON.parse(data)
    data['data'].map { |e| 'https://nimbus.kern.courts.ca.gov/case-details/' + e['caseId'] }
  end
  
  def parse(info_data, events_data, parties_data, case_folder, run_id)
    info_hash = get_info(info_data, case_folder, run_id)
    activites_array = get_activites(events_data, info_hash)
    parties_array = get_parties(parties_data, info_hash)
    [info_hash, activites_array, parties_array]
  end

  def find_pdfs_ids(response)
    data_set = JSON.parse(response)['data']
    data_set.map { |e| e['eventId'] } rescue []
  end

  def get_pdf_url(response)
    data_set = JSON.parse(response)['data'] rescue nil
    return nil if data_set.nil?

    id = data_set[0]['documentId']
    name = URI.escape (data_set[0]['documentName']) rescue nil
    return nil if name.nil?

    "https://nimbus.kern.courts.ca.gov/case-file/#{name}?documentId=#{id}"
  end

  def activity_relation_request(pdf_m5d_hash, activity_m5d_hash)
    case_relations_activity = {}
    case_relations_activity[:case_activities_md5] = activity_m5d_hash
    case_relations_activity[:case_pdf_on_aws_md5] = pdf_m5d_hash
    case_relations_activity[:md5_hash] = create_md5_hash(case_relations_activity)
    case_relations_activity
  end

  def pdf_on_aws(info_hash, pdf_name)
    data_hash_pdf = {}
    data_hash_pdf[:court_id]        = info_hash[:court_id]
    data_hash_pdf[:case_id]         = info_hash[:case_id]
    data_hash_pdf[:source_type]     = 'activities'
    data_hash_pdf[:aws_link]        = "us_courts_#{info_hash[:court_id].to_s}_#{info_hash[:case_id].to_s}_#{pdf_name}.pdf"
    data_hash_pdf[:source_link]     = info_hash[:data_source_url]
    data_hash_pdf                   = mark_empty_as_nil(data_hash_pdf)
    data_hash_pdf[:md5_hash]        = create_md5_hash(data_hash_pdf)
    data_hash_pdf[:run_id]          = info_hash[:run_id]
    data_hash_pdf
  end

  private

  def get_parties(parties_data, info_hash)
    data_hash_array = []
    return [] unless JSON.parse(parties_data)['statusCode'] == 200

    data_set = JSON.parse(parties_data)['data']
    data_set.each do |data|
      data_hash = {}
      data_hash[:court_id] = 83
      data_hash[:case_id] = info_hash[:case_id]
      data_hash[:data_source_url] = info_hash[:data_source_url]
      data_hash[:is_lawyer] = 0
      data_hash[:party_type] = data['partyType']
      data_hash[:party_name] = "#{data['partyLastName']} #{data['partyFirstName']} #{data['partyMiddleName']}".squish
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = info_hash[:run_id]
      data_hash_array << data_hash
    end
    data_hash_array
  end

  def get_info(info_data, case_folder, run_id)
    data_hash = {}
    return nil unless JSON.parse(info_data)['statusCode'] == 200

    data = JSON.parse(info_data)['data']
    data_hash[:court_id] = 83
    data_hash[:case_id] =  data['caseNumber']
    data_hash[:case_name] = data['style']
    data_hash[:case_filed_date] = data['caseFilingDate'].to_date
    data_hash[:case_type] = data['caseType']
    data_hash[:status_as_of_date] = data['caseStatus']
    data_hash[:data_source_url] = "https://portal.kern.courts.ca.gov/case-details/#{case_folder.gsub('.gz', '')}"
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash
  end

  def get_activites(events_data, info_hash)
    data_hash_array = []
    return [] unless JSON.parse(events_data)['statusCode'] == 200

    data_set = JSON.parse(events_data)['data']
    data_set.each do |data|
      data_hash = {}
      data_hash[:court_id] = 83
      data_hash[:case_id] = info_hash[:case_id]
      data_hash[:data_source_url] = info_hash[:data_source_url]
      data_hash[:activity_date] = data['eventDate'].to_date
      data_hash[:activity_type] = data['eventType']
      description = data['comment']
      description = (data['eventParties'].nil? or data['eventParties'].empty?) ? description : description + " Filed By: #{data['eventParties']}"
      data_hash[:activity_desc] = description.squish
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = info_hash[:run_id]
      data_hash[:activity_pdf] = data['eventId']
      data_hash_array << data_hash
    end
    data_hash_array
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
