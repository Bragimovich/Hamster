# frozen_string_literal: true
class Parser < Hamster::Scraper
    
  def token(token_page)
    token_content = Nokogiri::HTML(token_page.body)
    token_content.css('meta[name="csrf-token"]')[0]['content']
  end
    
  def parser(files,run_id)
    data = JSON.parse(files)
    data_hash = {}
    data_hash[:bar_number] = data["AttorneyNumber"]
    data_hash[:name] = data["FormalName"]  rescue nil
    data_hash[:date_admited] = Date.strptime(data["AdmissionDate"], '%m-%d-%Y').to_s rescue nil
    data_hash[:registration_status] = data["Status"]
    data_hash[:phone] = data["BusinessPhoneNumber"]
    data_hash[:law_firm_name] = data["Employer"]
    data_hash[:law_firm_address] = data["Address"].squish
    data_hash[:law_firm_zip] = data["ZipCode"]  rescue nil
    data_hash[:law_firm_city] = data["City"]    rescue nil
    data_hash[:law_firm_state] = data["State"]  rescue nil
    (data_hash[:law_firm_address].split.last.include? "County") ?  data_hash[:law_firm_county] = data_hash[:law_firm_address].split[-2] : data_hash[:law_firm_county] = nil
    data_hash[:law_school] = data["LawSchool"]
    data_hash[:job_title] = data["JobTitle"]
    data_hash[:admitted_by] = data["AdmittedBy"]
    data_hash[:discipline_history] = data["HasDiscipline"]
    data_hash[:administrative_sanctions] = data["HasSanctions"]
    data_hash[:data_source_url] = "https://www.supremecourt.ohio.gov/AttorneySearch/#/#{data["AttorneyNumber"]}/attyinfo"
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash[:first_name] = data["FirstName"]
    data_hash[:last_name] = data["LastName"]
    data_hash[:middle_name] = data["MiddleName"]
    mark_empty_as_nil(data_hash)
  end

  private

  def create_md5_hash(data_hash)
    data_hash = mark_empty_as_nil(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) || (value.to_s.squish == "") || (value.to_s.squish == " ") ? nil : value.to_s.squish.strip}
  end
end
