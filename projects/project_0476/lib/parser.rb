# frozen_string_literal: true
class Parser < Hamster::Parser

  def parse_data(profile_html,section_html,education_html,license_html,category_html,run_id,domain)
    data_hash = {}
    parsed_profile_html = parse_page(profile_html)
    infor = JSON.parse(license_html)
    data_hash[:bar_number]               = get_joined_info(license_html,'registrationNumber')
    data_hash[:lawyer_type]              = get_general_info(parsed_profile_html,'title')
    data_hash[:name]                     = get_general_info(parsed_profile_html,'displayName')
    data_hash[:law_firm_name]            = get_general_info(parsed_profile_html,'firmName')
    data_hash[:law_firm_address]         = get_address_info(parsed_profile_html,'primaryLocation','street')
    data_hash[:law_firm_zip]             = get_address_info(parsed_profile_html,'primaryLocation','postalCode')
    data_hash[:law_firm_city]            = get_address_info(parsed_profile_html,'primaryLocation','city')
    data_hash[:law_firm_state]           = get_address_info(parsed_profile_html,'primaryLocation','region')
    data_hash[:law_firm_county]          = get_address_info(parsed_profile_html,'primaryLocation','county')
    data_hash[:fax]                      = get_address_info(parsed_profile_html,'primaryLocation','fax')
    data_hash[:university]               = get_joined_info(education_html,'school')
    data_hash[:sections]                 = get_joined_info(section_html,'sectionName')
    data_hash[:date_admitted]            = get_license_date(license_html,'yearAdmission',domain)
    data_hash[:registration_status]      = get_general_info(infor[0],'statusName')
    data_hash[:website_id]               = get_general_info(parsed_profile_html,'id')
    data_hash[:member_type]              = get_general_info(parsed_profile_html,'memberType')
    data_hash[:bio]                      = get_general_info(parsed_profile_html,'biography')
    data_hash[:website]                  = get_general_info(parsed_profile_html,'website')
    data_hash[:linkedin]                 = get_general_info(parsed_profile_html,'socialLinkin')
    data_hash[:facebook]                 = get_general_info(parsed_profile_html,'socialFacebook')
    data_hash[:twitter]                  = get_general_info(parsed_profile_html,'socialTwitter')
    data_hash[:law_firm_website]         = get_general_info(parsed_profile_html,'website')
    data_hash[:phone]                    = get_address_info(parsed_profile_html,'primaryLocation','phone')
    data_hash[:email]                    = get_general_info(parsed_profile_html,'email')
    data_hash                            = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]                 = create_md5_hash(data_hash)
    data_hash[:practice_area]            = get_general_info(parsed_profile_html,'categories')
    data_hash[:first_name]               = get_general_info(parsed_profile_html,'firstName')
    data_hash[:last_name]                = get_general_info(parsed_profile_html,'lastName')
    data_hash[:middle_name]              = get_general_info(parsed_profile_html,'middleName')
    data_hash[:name_prefix]              = get_general_info(parsed_profile_html,'prefix')
    data_hash[:name_suffix]              = get_general_info(parsed_profile_html,'suffix')
    vanity_url                           = get_general_info(parsed_profile_html,'vanityURL').gsub(' ','%20')
    data_hash[:api_url]                  = get_api_url(domain,vanity_url)
    data_hash[:run_id]                   = run_id
    data_hash[:data_source_url]          = get_general_info(parsed_profile_html,'vanityURLFull')
    data_hash[:touched_run_id]           = run_id
    data_hash                            = mark_empty_as_nil(data_hash)
  end

  def parse_page(page)
    JSON.parse(page)
  end

  def delete_md5_key(data_array,key)
    return data_array.each{|data_hash| data_hash.delete(key)} unless data_array.empty?
    data_array
  end

  def get_md5_array(data_array)
    return data_array.map{|data_hash| data_hash[:md5_hash]} unless data_array.empty?
    data_array
  end

  private

  def get_api_url(domain,vanity_url)
    (vanity_url == nil) ? nil : "https://#{domain}.reliaguide.com/api/public/profiles/#{vanity_url}"
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def get_license_date(license_html,key,domain)
    (domain == 'inbar') ? date_format = '%Y/%m/%d' : date_format = '%m/%d/%Y'
    DateTime.strptime(parse_page(license_html).first[key].split.first.gsub('-','/'),"#{date_format}").to_date rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "--") ? nil : value.to_s.squish}
  end

  def get_joined_info(html,key)
    parse_page(html).map{|data_hash| data_hash[key]}.to_json
  end

  def get_practice_areas(category_html,key)
    parse_page(category_html).map{|data_hash| data_hash[key]}.to_json
  end

  def get_general_info(data_hash,key)
    data_hash[key]
  end

  def get_address_info(data_hash,key,inner_key)
    data_hash[key][inner_key]
  end

end
