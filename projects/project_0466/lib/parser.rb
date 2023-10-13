class Parser < Hamster::Parser

  def get_links(html)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    page.css('td.gridText a').map{|a| a['href']}.select{|link| link.include? 'caseId='}.uniq
  end

  def check_next(html)
    page = Nokogiri::HTML(html.body)
    page.css('tr td a')[-1].text
  end

  def get_next_page_url(response)
    page = Nokogiri::HTML(response.body)
    link = page.css('tr td a')[-1]["href"]
    "https://eapps.courts.state.va.us#{link}"
  end

  def prepare_info_hash(html, url, run_id, court_id)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    if court_id == 347
      tags = ["#tribunalRecord", "#tribunal", '#petitionEntryDate', "#dspDisposition", "#dspDispositionDate"]
    else
      tags = ["#tribunalCaseNumber", "#lowerTribunal", '#noticeOfAplDt', "#tjpLODisposition", "#tjpLODispositionDt"]
    end
    data_hash={}
    data_hash["status_as_of_date"] = nil
    data_hash["disposition_or_status"] = nil
    data_hash["lower_case_id"] = nil
    data_hash["court_id"] = court_id
    data_hash["case_id"], data_hash["case_name"], data_hash["case_type"] = get_basic_info(page)
    data_hash["full_lower_case_id"] = get_value(page, tags[0])
    data_hash["lower_court_name"] = get_value(page, tags[1])
    data_hash["case_filed_date"] = DateTime.strptime(get_value(page, tags[2]), '%m-%d-%Y').to_date rescue nil
    data_hash["disposition_or_status"] = get_disposition_value(page, tags[3])
    data_hash["lower_case_id"] = data_hash["full_lower_case_id"]
    data_hash["status_as_of_date"] = (url.include? 'inactive') ? 'Inactive' : 'Active'
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    data_hash["md5_hash"] = create_md5_hash(data_hash)
    data_hash["run_id"] = run_id
    data_hash["touched_run_id"] = run_id
    data_hash["data_source_url"] = "https://eapps.courts.state.va.us#{url}"
    data_hash
  end

  def valid_record?(html)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    page.css('#caseNumber').count > 0 ? true : false
  end

  def prepare_additional_info_hash(html, url, run_id, court_id)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    if court_id == 347
      tags = ["#tribunalRecord", "#tribunal", "#dspDisposition", "#dspDispositionDate"]
    else
      tags = ["#tribunalCaseNumber", "#lowerTribunal", "#tjpLODisposition", "#tjpLODispositionDt"]
    end
    additional_info_array = []
    lower_case_id = get_value(page, tags[0])

    return additional_info_array if lower_case_id.empty?

    data_hash={}
    data_hash["court_id"] = court_id
    data_hash["case_id"] = get_value(page, '#caseNumber')
    data_hash["lower_court_name"] = get_value(page, tags[1])
    data_hash["lower_case_id"] = lower_case_id.squish
    data_hash['disposition'] = get_disposition_value(page, tags[2])
    data_hash["lower_judgement_date"] = (url.include? 'inactive') ? 'Inactive' : 'Active'
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    data_hash["md5_hash"] = create_md5_hash(data_hash)
    data_hash["run_id"] = run_id
    data_hash["touched_run_id"] = run_id
    data_hash["data_source_url"]= "https://eapps.courts.state.va.us#{url}"
    additional_info_array << data_hash
    additional_info_array
  end

  def get_aws_files_hash(html,court_id)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    data_hash = {}
    data_hash["court_id"] = court_id
    data_hash["case_id"] = get_value(page, '#caseNumber')
    data_hash["source_type"] = 'info'
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    data_hash
  end

  def party_info_hash(html, url, run_id, md5hash, court_id)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    party_array = []
    party_array.concat(get_case_parties(page, url, run_id, md5hash, court_id))
    party_array.concat(get_attorney(page, url, run_id, md5hash, court_id))
    party_array
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  private

  def get_disposition_value(page, tag)
    disposition_value = get_value(page, tag)
    disposition_value = get_value(page, '#prDisposition') unless disposition_value
    disposition_value = get_value(page, '#mpThreeJudgeDisposition') unless disposition_value
    disposition_value
  end

  def get_case_parties(page, url, run_id, md5hash, court_id)
    tags = ['#listAllPartiesAPL tr', '#listofPartiesAPE tr']
    party_array = []
    tags.each do |party|
      page.css(party).each do |name|
        break if name.text.squish == ''
        next if name.text.squish.include? "Alias"
        party_hash = {}
        party_hash["court_id"] = court_id
        party_hash["case_id"] = get_value(page, '#caseNumber')
        party_hash["is_lawyer"] = 0
        party_hash["party_name"] = name.css('td')[0].text.split('(').first.squish
        party_type_class = party == '#listAllPartiesAPL tr' ? "#listofPartiesAPL" : "#listofPartiesAPE"
        party_hash["party_type"] = page.css("#{party_type_class} th.gridheader")[0].text.squish
        party_hash["party_law_firm"] = get_firm_name(name.text)
        party_hash = mark_empty_as_nil(party_hash) unless party_hash.nil?
        party_hash["md5_hash"] = create_md5_hash(party_hash)
        next if md5hash.include? party_hash["md5_hash"]
        party_hash["run_id"] = run_id
        party_hash["touched_run_id"] = run_id
        party_hash["lower_link"]= "https://eapps.courts.state.va.us#{url}"
        party_array << party_hash
      end
    end
    party_array
  end

  def get_attorney(page, url, run_id, md5hash, court_id)
    tags = ['#listAllAttorneysAPL tr', '#listAllAttorneysAPE tr']
    attorney_array = []
    tags.each do |party|
      page.css(party).each do |name|
        party_hash = {}
        party_hash["court_id"] = court_id
        party_hash["case_id"] = get_value(page, '#caseNumber')
        party_hash["is_lawyer"] = 1
        party_hash["party_name"] = name.text.squish.split('(').first
        party_type_class = party == '#listAllAttorneysAPL tr' ? "#listofPartiesAPL" : "#listofPartiesAPE"
        party_hash["party_type"] = (page.css("#{party_type_class} th.gridheader")[0].text.squish) +" Attorney"
        party_hash["party_law_firm"] = get_firm_name(name.text)
        party_hash = mark_empty_as_nil(party_hash) unless party_hash.nil?
        party_hash["md5_hash"] = create_md5_hash(party_hash)
        next if md5hash.include? party_hash["md5_hash"]
        party_hash["run_id"] = run_id
        party_hash["touched_run_id"] = run_id
        party_hash["lower_link"]= "https://eapps.courts.state.va.us#{url}"
        attorney_array << party_hash
      end
    end
    attorney_array
  end
  
  def get_firm_name(name)
    law_firm = nil
    law_firm = name.split('(').last.gsub(')','').squish if name.include? "("
    law_firm
  end

  def get_basic_info(page)
    case_id = get_value(page, '#caseNumber')
    case_name = get_name(page)
    case_type = get_value(page, '#caseType')
    [case_id, case_name, case_type]
  end

  def get_name(page)
    first_name = page.css('#listAllPartiesAPL tr')[0].css('td')[0].text.squish
    last_name = page.css('#listAllPartiesAPE tr')[0].css('td')[0].text.squish
    "#{first_name} .V. #{last_name}"
  end

  def get_value(page,tag)
    page.css(tag)[0]["value"] rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end
end
