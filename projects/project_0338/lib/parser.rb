# frozen_string_literal: true

class Parser < Hamster::Parser

  DATA_TYPE_STRING = 0
  DATA_TYPE_INTEGER = 1
  DATA_TYPE_DECIMAL = 2
  ROLE_TYPE_ARRAY   = ['Chair', 'Deputy Treasurer', 'Treasurer', 'Depository']

  def parse_json(body)
    logger.info "JSON"
    JSON.parse(body)["data"]
  end

  def parse_html(body)
    Nokogiri::HTML(body.force_encoding('ISO-8859-1').encode('UTF-8'))
  end

  def parse_candidate(candidate_json, year, contact_response, entity_id, run_id)
    candidate = candidate_json.first
    candidate_hash = {}
    candidate_hash["data_source_url"] = "https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/candidates/#{candidate["RegisteredEntityID"]}/#{year}/"
    candidate_hash["registered_entity_id"] = prevent_nil(candidate["RegisteredEntityID"], DATA_TYPE_STRING)
    candidate_hash["master_name_id"] = candidate["MasterNameID"]
    candidate_hash["committee_full_name"] = prevent_nil(candidate["CommitteeFullName"], DATA_TYPE_STRING)
    candidate_hash["candidate_full_name"] = prevent_nil(candidate["CandidateFullName"], DATA_TYPE_STRING)
    candidate_hash["party_affiliation"] = candidate["PartyAffiliation"]
    candidate_hash["election_cycle_start_date"] = candidate["ElectionCycleStartDate"]
    candidate_hash["election_cycle_end_date"] = candidate["ElectionCycleEndDate"]
    candidate_hash["election_year"] = candidate["ElectionYear"]
    candidate_hash["office_sought_full_name"] = candidate["OfficeSoughtFullName"]
    candidate_hash["incumbent"] = candidate["Incumbent"]
    candidate_hash["public_subsidy_date"] = candidate["PublicSubsidyDate"]
    candidate_hash["affidavit_of_candidacy_date"] = candidate["AffidavitOfCandidacyDate"]
    candidate_hash["public_subsidy_amount"] = candidate["PublicSubsidyAmount"]
    candidate_hash["affidavit_of_contribution_date"] = candidate["AffidavitOfContributionDate"]
    candidate_hash["primary_election_winner"] = candidate["PrimaryElectionWinner"]
    candidate_hash["general_election_winner"] = candidate["GeneralElectionWinner"]
    candidate_hash["registration_date"] = candidate["RegistrationDate"]
    candidate_hash["district"] = candidate["District"]
    candidate_hash["affidavit_of_contribution"] = candidate["AffidavitOfContribution"]
    candidate_hash["public_subsidy"] = candidate["PublicSubsidy"]
    candidate_hash["public_subsidy_qualified"] = candidate["PublicSubsidyQualified"]
    candidate_hash["affidavit_of_candidacy"] = candidate["AffidavitOfCandidacy"]
    candidate_hash["has_primary"] = candidate["HasPrimary"]
    candidate_hash["unopposed_candidate"] = candidate["UnopposedCandidate"]
    candidate_hash["first_time_candidate"] = candidate["FirstTimeCandidate"]
    candidate_hash["spend_limit_waived"] = candidate["SpendLimitWaived"]
    candidate_hash["economic_interest_filed"] = candidate["EconomicInterestFiled"]
    candidate_hash["economic_interest_filed_date"] = candidate["EconomicInterestFiledDate"]
    candidate_hash["camp_exp_limit"] = candidate["CampExpLimit"]
    candidate_hash["office_district_description"] = candidate["OfficeDistrictDescription"]
    candidate_hash["office_district_key"] = candidate["OfficeDistrictKey"]
    candidate_hash["office_key"] = candidate["OfficeKey"]
    candidate_hash["district_key"] = candidate["DistrictKey"]
    candidate_hash["termination_date"] = candidate["TerminationDate"]
    candidate_hash["special_election_indicator"] = candidate["SpecialElectionIndicator"]
    candidate_hash["registered_entity_type"] = candidate["RegisteredEntityType"]
    candidate_hash["affidavit_year"] = candidate["AffidavitYear"]
    candidate_hash["candidate_master_name_id"] = candidate["CandidateMasterNameID"]
    candidate_hash["ltgc_master_name_id"] = candidate["LTGCMasterNameID"]
    candidate_hash["ltgc_formatted_name"] = candidate["LTGCFormattedName"]
    candidate_hash["office_sought"] = candidate["OfficeSought"]
    candidate_hash["public_subsidy_estimate"] = candidate["PublicSubsidyEstimate"]
    candidate_hash["contested_primary"] = candidate["ContestedPrimary"]
    contact_response = contact_response.gsub(/\\/,'').gsub('{',"").gsub('}', '').gsub('"',"'")
    position_regex = /<span\s+class=["']position["']>(.*?)<\/span>/
    city_state_zip_regex = /<span\s+class=["']city-state-zip["']>(.*?)<\/span>/
    street_regex = /<span\s+class=["']street["']>(.*?)<\/span>/
    positions = contact_response.scan(position_regex)
    city_state_zip = contact_response.scan(city_state_zip_regex)
    streets = contact_response.scan(street_regex)
    array_index = (0..1).to_a
    array_index.each do |num|
      position = positions[num].first.downcase
      next unless position == "committee" or position == "candidate"
      candidate_hash["#{position}_street_address"] = streets[num].first
      candidate_hash["#{position}_city_state_zip"] = city_state_zip[num].first
    end
    candidate_hash = mark_empty_as_nil(candidate_hash)
    candidate_hash['md5_hash'] = create_md5_hash(candidate_hash)
    candidate_hash["last_scrape_date"] = Date.today
    candidate_hash["next_scrape_date"] = Date.today + 1
    candidate_hash["expected_scrape_frequency"] = 'daily'
    candidate_hash["dataset_name_prefix"] = 'minnesota_campaign_finance'
    candidate_hash["scrape_status"] = 'live'
    candidate_hash["created_by"] = 'Muhammad Qasim'
    candidate_hash['run_id'] = run_id
    candidate_hash
  end
  
  def parse_committee(committee_json, year, run_id)
    committee = committee_json.first
    committee_hash = {}
    committee_hash["data_source_url"] = "https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/political-committee-fund/#{committee["RegisteredEntityID"]}/#{year}/"
    committee_hash["registered_entity_id"] = prevent_nil(committee["RegisteredEntityID"], DATA_TYPE_STRING)
    committee_hash["year"] = year
    committee_hash["role_type"] = committee["RoleType"]
    committee_hash["master_name_id"] = committee["MasterNameID"]
    committee_hash["formatted_name"] = prevent_nil(committee["FormattedName"], DATA_TYPE_STRING)
    committee_hash["address1"] = prevent_nil(committee["Address1"], DATA_TYPE_STRING)
    committee_hash["address2"] = prevent_nil(committee["Address2"], DATA_TYPE_STRING)
    committee_hash["city"] = prevent_nil(committee["City"], DATA_TYPE_STRING)
    committee_hash["state"] = prevent_nil(committee["State"], DATA_TYPE_STRING)
    committee_hash["zip_code"] = prevent_nil(committee["ZipCode"], DATA_TYPE_STRING)
    committee_hash["phone_number"] = committee["PhoneNumber"]
    committee_hash["email_address"] = committee["EmailAddress"]
    committee_hash["web_address"] = committee["WebAddress"]
    committee_hash["committee_type"] = committee["CommitteeType"]
    committee_hash["first_registered_date"] = Date.strptime(committee["FirstRegisteredDate"], '%m/%d/%Y')
    committee_hash["registered_entity_type"] = committee["RegisteredEntityType"]
    committee_hash["role_sort_order"] = committee["RoleSortOrder"]
    range_loop = [1,2,-1]
    range_loop.each do |num|
      ROLE_TYPE_ARRAY.each do |role_type|
        logger.info "ROLE = ============ = #{role_type}"
        next if committee_json[num].nil? 
        if committee_json[num]["RoleType"].eql?(role_type)
          role_type = role_type.downcase.split.join('_')
          committee_hash["#{role_type}_role_type"] = committee_json[num]["RoleType"]
          committee_hash["#{role_type}_master_name_id"] = committee_json[num]["MasterNameID"]
          committee_hash["#{role_type}_formatted_name"] = committee_json[num]["FormattedName"]
          committee_hash["#{role_type}_address1"] = committee_json[num]["Address1"]
          committee_hash["#{role_type}_address2"] = committee_json[num]["Address2"]
          committee_hash["#{role_type}_city"] = committee_json[num]["City"]
          committee_hash["#{role_type}_state"] = committee_json[num]["State"]
          committee_hash["#{role_type}_zip_code"] = committee_json[num]["ZipCode"]
          committee_hash["#{role_type}_phone_number"] = committee_json[num]["PhoneNumber"]
          committee_hash["#{role_type}_email_address"] = committee_json[num]["EmailAddress"]
          committee_hash["#{role_type}_web_address"] = committee_json[num]["WebAddress"]
          committee_hash["#{role_type}_committee_type"] = committee_json[num]["CommitteeType"]
          committee_hash["#{role_type}_first_registered_date"] = Date.strptime(committee_json[num]["FirstRegisteredDate"], '%m/%d/%Y')
          committee_hash["#{role_type}_registered_entity_type"] = committee_json[num]["RegisteredEntityType"]
          committee_hash["#{role_type}_role_sort_order"] = committee_json[num]["RoleSortOrder"]
        end
      end
    end
    committee_hash = mark_empty_as_nil(committee_hash)
    committee_hash['md5_hash'] = create_md5_hash(committee_hash)
    committee_hash["last_scrape_date"] = Date.today
    committee_hash["next_scrape_date"] = Date.today + 1
    committee_hash["expected_scrape_frequency"] = 'daily'
    committee_hash["dataset_name_prefix"] = 'minnesota_campaign_finance'
    committee_hash["scrape_status"] = 'live'
    committee_hash["created_by"] = 'Muhammad Qasim'
    committee_hash['run_id'] = run_id
    committee_hash
  end

  def parse_party(party_json, year, run_id)
    party = party_json.first
    party_hash = {}
    party_hash["data_source_url"] = "https://cfb.mn.gov/reports-and-data/viewers/campaign-finance/party-unit/#{party["RegisteredEntityID"]}/#{year}/"
    party_hash["registered_entity_id"] = prevent_nil(party["RegisteredEntityID"], DATA_TYPE_STRING)
    party_hash["year"] = year
    party_hash["role_type"] = party["RoleType"]
    party_hash["master_name_id"] = party["MasterNameID"]
    party_hash["formatted_name"] = prevent_nil(party["FormattedName"], DATA_TYPE_STRING)
    party_hash["address1"] = prevent_nil(party["Address1"], DATA_TYPE_STRING)
    party_hash["address2"] = prevent_nil(party["Address2"], DATA_TYPE_STRING)
    party_hash["city"] = prevent_nil(party["City"], DATA_TYPE_STRING)
    party_hash["state"] = prevent_nil(party["State"], DATA_TYPE_STRING)
    party_hash["zip_code"] = prevent_nil(party["ZipCode"], DATA_TYPE_STRING)
    party_hash["phone_number"] = party["PhoneNumber"]
    party_hash["email_address"] = party["EmailAddress"]
    party_hash["web_address"] = party["WebAddress"]
    party_hash["registered_entity_type"] = party["RegisteredEntityType"]
    party_hash["role_sort_order"] = party["RoleSortOrder"]
    range_loop = [1,2,-1]
    range_loop.each do |num|
      ROLE_TYPE_ARRAY.each do |role_type|
        logger.info "ROLE = ============ = #{role_type}"
        next if party_json[num].nil?
        if party_json[num]["RoleType"].eql?(role_type)
          role_type = role_type.downcase.split.join('_')
          party_hash["#{role_type}_role_type"] = party_json[num]["RoleType"]
          party_hash["#{role_type}_master_name_id"] = party_json[num]["MasterNameID"]
          party_hash["#{role_type}_formatted_name"] = party_json[num]["FormattedName"]
          party_hash["#{role_type}_address1"] = party_json[num]["Address1"]
          party_hash["#{role_type}_address2"] = party_json[num]["Address2"]
          party_hash["#{role_type}_city"] = party_json[num]["City"]
          party_hash["#{role_type}_state"] = party_json[num]["State"]
          party_hash["#{role_type}_zip_code"] = party_json[num]["ZipCode"]
          party_hash["#{role_type}_phone_number"] = party_json[num]["PhoneNumber"]
          party_hash["#{role_type}_email_address"] = party_json[num]["EmailAddress"]
          party_hash["#{role_type}_web_address"] = party_json[num]["WebAddress"]
          party_hash["#{role_type}_registered_entity_type"] = party_json[num]["RegisteredEntityType"]
          party_hash["#{role_type}_role_sort_order"] = party_json[num]["RoleSortOrder"]
        end
      end
    end
    party_hash = mark_empty_as_nil(party_hash)
    party_hash['md5_hash'] = create_md5_hash(party_hash)
    party_hash["last_scrape_date"] = Date.today
    party_hash["next_scrape_date"] = Date.today + 1
    party_hash["expected_scrape_frequency"] = 'daily'
    party_hash["dataset_name_prefix"] = 'minnesota_campaign_finance'
    party_hash["scrape_status"] = 'live'
    party_hash["created_by"] = 'Muhammad Qasim'
    party_hash['run_id'] = run_id
    party_hash
  end
  
  def csv_url_parser(html, file_title)
    doc = Nokogiri::HTML(html)
    main_section = doc.at_css('[id="main"]')
    main_section.search('table').each_with_index do |table, index_table|
      table.search('tr').each_with_index do |tr, index_tr|
        td_elements = tr.search('td')
        td_elements.search('td').each_with_index do |td, index_td|
          if td.children.text.include? file_title
            return td_elements[index_td + 1].children.first['href']
          end
        end
      end
    end
  end
  
  private 

  def prevent_nil(value, data_type)
    if data_type == DATA_TYPE_STRING
      value.nil? ? '' : value
    elsif (data_type == DATA_TYPE_INTEGER) || (data_type == DATA_TYPE_DECIMAL)
      value.nil? ? -1 : value
    end
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values do |value|
      value = value.strip unless value.nil? or value.class != String
      value.to_s.squish.empty? ? nil : value
    end
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

end
