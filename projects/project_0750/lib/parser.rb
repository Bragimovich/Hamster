# frozen_string_literal: true
require 'roo'

class Parser < Hamster::Parser

  def initialize(**params)
    super
    @keeper = Keeper.new
  end

  def get_csv_data(file, run_id)
    @run_id = run_id
    data_hash = {}
    if file.include?("Expenditure")
     logger.info "Expenditure"
     expenditures = get_expenditures_data(file, run_id)
    elsif file.include?("Candidate")
      logger.info "Candidate"
      candidates = get_candidates_data(file, run_id)
    else
      logger.info "Receipts"
      receipts = get_receipts_data(file, run_id)
    end
    data_hash = {
      "expenditures" => expenditures,
      "candidates" => candidates,
      "receipts" => receipts,
    }
  end  

  def get_xlsx_data(file, run_id)
    @run_id = run_id
    data_hash = {}
    xlsx = Roo::Spreadsheet.open(file)
    xlsx = xlsx.parse(headers: true)
    if file.include?("Candidate_Listing_2018")
      logger.info "Candidate_Listing_2018"
      candidate_2018 = get_candidate_2018_data(xlsx, run_id)
    elsif file.include?("Candidate_Listing_2020")
      logger.info "Candidate_Listing_2020"
      candidate_2020 = get_candidate_2020_data(xlsx, run_id)
    else
      logger.info "Candidate_Listing_2021"
      candidate_2021 = get_candidate_2021_data(xlsx, run_id)
    end
    data_hash = {
      "candidate_2018" => candidate_2018,
      "candidate_2020" => candidate_2020,
      "candidate_2021" => candidate_2021,
    }
  end   

  def get_txt_data(file, run_id, file_name)
    @run_id = run_id
    data_hash = {}
    voters = get_voters_data(file, run_id, file_name)
    data_hash = {
      "voters" => voters,
    }
  end

  private

  attr_accessor :keeper

  def get_expenditures_data(file, run_id)
    insertion_size = 1000
    expenditures_array = []
    count = 0
    CSV.foreach(file, headers: true, encoding: 'ISO-8859-1') do |row|
      count += 1
      # next if row["Date Occured"].nil? or row["Date Occured"].match(/^([0][1-9]|[1][0-2])\/([0-2][0-9]|[3][0-1])\/\d{4}$/).nil? rescue byebug
      row = row.map { |cell| cell.class == String ? cell.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '[unknown]').gsub(/"/, '""') : cell}.to_h
      expenditures_hash = {}
      expenditures_hash["name"] = row["Name"]
      expenditures_hash["street_line_1"] = row["Street Line 1"]
      expenditures_hash["street_line_2"] = row["Street Line 2"]
      expenditures_hash["city"] = row["City"]
      expenditures_hash["state"] = row["State"]
      expenditures_hash["zip_code"] = row["Zip Code"]
      expenditures_hash["profession_job_title"] = row["Profession/Job Title"]
      expenditures_hash["employer_name_specific_field"] = row["Employer's Name/Specific Field"]
      expenditures_hash["transaction_type"] = row["Transction Type"]
      expenditures_hash["committee_name"] = row["Committee Name"]
      expenditures_hash["committee_sboe_id"] = row["Committee SBoE ID"]
      expenditures_hash["committee_street_1"] = row["Committee Street 1"]
      expenditures_hash["committee_street_2"] = row["Committee Street 2"]
      expenditures_hash["committee_city"] = row["Committee City"]
      expenditures_hash["committee_state"] = row["Committee State"]
      expenditures_hash["committee_zip_code"] = row["Committee Zip Code"]
      expenditures_hash["report_name"] = row["Report Name"]
      expenditures_hash["date_occurred"] = DateTime.strptime(row["Date Occured"] , "%m/%d/%Y").to_date rescue byebug
      expenditures_hash["account_code"] = row["Account Code"]
      expenditures_hash["amount"] = row["Amount"]
      expenditures_hash["form_of_payment"] = row["Form of Payment"]
      expenditures_hash["purpose"] = row["Purpose"]
      expenditures_hash["candidate_referendum_name"] = row["Candidate/Referendum Name"]
      expenditures_hash["declaration"] = row["Declaration"]
      expenditures_hash["run_id"] = run_id
      expenditures_hash = mark_empty_as_nil(expenditures_hash)
      expenditures_array.push(expenditures_hash)
      if expenditures_array.size == insertion_size
        logger.info "current value of count is #{count} ........!!!!!!!!"
        keeper.insert_expenditures_csv_data(expenditures_array)
        expenditures_array = []
      end
    end
    keeper.insert_expenditures_csv_data(expenditures_array) unless expenditures_array.empty?
  end

  def get_candidates_data(file, run_id)
    insertion_size = 1000
    candidates_array = []
    count = 0
    CSV.foreach(file, headers: true, encoding: 'ISO-8859-1') do |row|
      count += 1
      row = row.map { |cell| cell.class == String ? cell.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '[unknown]').gsub(/"/, '""') : cell}.to_h
      candidates_hash = {}
      candidates_hash["election_date"] = DateTime.strptime(row['election_dt'] , "%m/%d/%Y").to_date 
      candidates_hash["county_name"] = row["county_name"] 
      candidates_hash["contest_name"] = row["contest_name"] 
      candidates_hash["name_on_ballot"] = row["name_on_ballot"].gsub(/"/, '""')
      candidates_hash["first_name"] = row["first_name"] 
      candidates_hash["middle_name"] = row["middle_name"] 
      candidates_hash["last_name"] = row["last_name"] 
      candidates_hash["name_suffix_lbl"] = row["name_suffix_lbl"] 
      candidates_hash["nick_name"] = row["nick_name"] 
      candidates_hash["street_address"] = row["street_address"] 
      candidates_hash["city"] = row["city"] 
      candidates_hash["state"] = row["state"] 
      candidates_hash["zip_code"] = row["zip_code"] 
      candidates_hash["phone"] = row["phone"] 
      candidates_hash["office_phone"] = row["office_phone"] 
      candidates_hash["business_phone"] = row["business_phone"] 
      candidates_hash["candidacy_dt"] = DateTime.strptime(row["candidacy_dt"] , "%m/%d/%Y").to_date
      candidates_hash["party_contest"] = row["party_contest"] 
      candidates_hash["party_candidate"] = row["party_candidate"] 
      is_unexpired = row["is_unexpired"].to_s.downcase == "true" ? 1 : 0 if row["is_unexpired"].class != Integer
      has_primary = row["has_primary"].to_s.downcase == "true" ? 1 : 0 if row["has_primary"].class != Integer
      is_partisan = row["is_partisan"].to_s.downcase == "true" ? 1 : 0 if row["is_partisan"].class != Integer
      candidates_hash["is_unexpired"] = is_unexpired
      candidates_hash["has_primary"] = has_primary
      candidates_hash["is_partisan"] = is_partisan
      candidates_hash["vote_for"] = row["vote_for"] 
      candidates_hash["term"] = row["term"] 
      candidates_hash["run_id"] = run_id 
      candidates_hash = mark_empty_as_nil(candidates_hash)
      candidates_array.push(candidates_hash)
      if candidates_array.size == insertion_size
        keeper.insert_candidates_csv_data(candidates_array)
        candidates_array = []
      end
    end
    keeper.insert_candidates_csv_data(candidates_array) unless candidates_array.empty?
  end

  def get_receipts_data(file, run_id)
    insertion_size = 1000
    receipts_array = []
    count = 0
    CSV.foreach(file, headers: true, encoding: 'ISO-8859-1') do |row|
      count += 1
      # next if row["Date Occured"].nil? or row["Date Occured"].match(/^([0][1-9]|[1][0-2])\/([0-2][0-9]|[3][0-1])\/\d{4}$/).nil? rescue byebug
      row = row.map { |cell| cell.class == String ? cell.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '[unknown]').gsub(/"/, '""') : cell}.to_h
      receipts_hash = {}
      receipts_hash["name"] = row["Name"]
      receipts_hash["street_line_1"] = row["Street Line 1"]
      receipts_hash["street_line_2"] = row["Street Line 2"]
      receipts_hash["city"] = row["City"]
      receipts_hash["state"] = row["State"]
      receipts_hash["zip_code"] = row["Zip Code"]
      receipts_hash["profession_job_title"] = row["Profession/Job Title"]
      receipts_hash["employer_name_specific_field"] = row["Employer's Name/Specific Field"]
      receipts_hash["transaction_type"] = row["Transction Type"]
      receipts_hash["committee_name"] = row["Committee Name"]
      receipts_hash["committee_sboe_id"] = row["Committee SBoE ID"]
      receipts_hash["committee_street_1"] = row["Committee Street 1"]
      receipts_hash["committee_street_2"] = row["Committee Street 2"]
      receipts_hash["committee_city"] = row["Committee City"]
      receipts_hash["committee_state"] = row["Committee State"]
      receipts_hash["committee_zip_code"] = row["Committee Zip Code"]
      receipts_hash["report_name"] = row["Report Name"]
      receipts_hash["date_occurred"] = DateTime.strptime(row["Date Occured"] , "%m/%d/%Y").to_date rescue byebug
      receipts_hash["account_code"] = row["Account Code"]
      receipts_hash["amount"] = row["Amount"]
      receipts_hash["form_of_payment"] = row["Form of Payment"]
      receipts_hash["purpose"] = row["Purpose"]
      receipts_hash["candidate_referendum_name"] = row["Candidate/Referendum Name"]
      receipts_hash["declaration"] = row["Declaration"]
      receipts_hash["run_id"] = run_id
      receipts_hash = mark_empty_as_nil(receipts_hash)
      receipts_array.push(receipts_hash)
      if receipts_array.size == insertion_size
        keeper.insert_receipts_csv_data(receipts_array)
        receipts_array = []
      end
    end
    keeper.insert_receipts_csv_data(receipts_array) unless receipts_array.empty?
  end

  def get_voters_data(file, run_id, file_name)
    insertion_size = 100
    voters_array = []
    headers = nil
    count = 0
    File.open(file, "r:UTF-8") do |file|
      file.each_line do |line|
        line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        row = line.chomp.split("\t").map { |cell| cell.gsub(/\\$/, '').gsub(/\\"/, '') }
        if headers.nil?
          headers = row
        end
        break if headers != nil
      end
    end
    File.open(file, "r:UTF-8") do |file|
      file.each_line do |line|
        count += 1
        if headers != nil
          line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          row = line.chomp.split("\t").map { |cell| cell.gsub(/\\$/, '').gsub(/\\"/, '') }
          next if row == headers
          voter_hash = Hash[headers.zip(row)]
          voter_hash["run_id"] = run_id
          voter_hash["file_name"] = file_name
          voter_hash["row_num"] = count
          voter_hash = voter_hash.transform_keys { |key| key.class == String ? key.gsub(/(^"|"$)/, '') : key }.transform_values { |value| value.class == String ?  value.gsub(/(^"|"$)/, '') : value }
          voter_hash = mark_empty_as_nil(voter_hash)
          voters_array.push(voter_hash)
          if voters_array.size == insertion_size
            keeper.insert_voter_txt_data(voters_array)
            voters_array = []
          end
        end
      end
    end
    keeper.insert_voter_txt_data(voters_array) unless voters_array.empty?
  end

  def get_candidate_2018_data(file, run_id)
    insertion_size = 1000
    hash_array = []
    header = file.first
    file.each do |row|
      next if row == header
      data_hash = {}
      data_hash["election_dt"] = row["election_dt"].strftime("%m-%d-%Y")
      data_hash["county_name"] = row["county_name"]
      data_hash["contest_name"] = row["contest_name"]
      data_hash["name_on_ballot"] = row["name_on_ballot"]
      data_hash["first_name"] = row["first_name"]
      data_hash["middle_name"] = row["middle_name"]
      data_hash["last_name"] = row["last_name"]
      data_hash["name_suffix_lbl"] = row["name_suffix_lbl"]
      data_hash["nick_name"] = row["nick_name"]
      data_hash["candidacy_dt"] = DateTime.strptime(row["candidacy_dt"] , "%m/%d/%Y").to_date 
      data_hash["party_contest"] = row["party_contest"]
      data_hash["party_candidate"] = row["party_candidate"]
      is_unexpired = row["is_unexpired"].to_s.downcase == "true" ? 1 : 0 if row["is_unexpired"].class != Integer
      has_primary = row["has_primary"].to_s.downcase == "true" ? 1 : 0 if row["has_primary"].class != Integer
      is_partisan = row["is_partisan"].to_s.downcase == "true" ? 1 : 0 if row["is_partisan"].class != Integer
      data_hash["is_unexpired"] = is_unexpired
      data_hash["has_primary"] = has_primary
      data_hash["is_partisan"] = is_partisan
      data_hash["vote_for"] = row["vote_for"]
      data_hash["term"] = row["term"]
      data_hash["addr1"] = row["addr1"]
      data_hash["addr2"] = row["addr2"]
      data_hash["addr3"] = row["addr3"]
      data_hash["city"] = row["city"]
      data_hash["state"] = row["state"]
      data_hash["zip_code"] = row["zip"]
      data_hash["phone"] = row["Phone Number"]
      data_hash["email"] = row["email"]
      data_hash["run_id"] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      hash_array.push(data_hash)
      if hash_array.size == insertion_size
        keeper.insert_candidate_2018_xlsx_data(hash_array)
        hash_array = []
      end
    end
    keeper.insert_candidate_2018_xlsx_data(hash_array) unless hash_array.empty?
  end
  
  def get_candidate_2020_data(file, run_id)
    insertion_size = 1000
    hash_array = []
    header = file.first
    file.each do |row|
      next if row == header
      data_hash = {}
      data_hash["election_dt"] = DateTime.strptime(row["election_dt"] , "%m/%d/%Y").to_date 
      data_hash["county_name"] = row["county_name"]
      data_hash["contest_name"] = row["contest_name"]
      data_hash["name_on_ballot"] = row["name_on_ballot"]
      data_hash["first_name"] = row["first_name"]
      data_hash["middle_name"] = row["middle_name"]
      data_hash["last_name"] = row["last_name"]
      data_hash["name_suffix_lbl"] = row["name_suffix_lbl"]
      data_hash["nick_name"] = row["nick_name"]
      data_hash["street_address"] = row["street_address"]
      data_hash["city"] = row["city"]
      data_hash["state"] = row["state"]
      data_hash["zip_code"] = row["zip_code"]
      data_hash["phone"] = row["phone"]
      data_hash["office_phone"] = row["office_phone"]
      data_hash["business_phone"] = row["business_phone"]
      data_hash["campaign_email"] = row["campaign_email"]
      data_hash["party_candidate"] = row["party_candidate"]
      data_hash["candidacy_dt"] = DateTime.strptime(row["candidacy_dt"] , "%m/%d/%Y").to_date 
      is_unexpired = row["is_unexpired"].to_s.downcase == "true" ? 1 : 0 if row["is_unexpired"].class != Integer
      has_primary = row["has_primary"].to_s.downcase == "true" ? 1 : 0 if row["has_primary"].class != Integer
      is_partisan = row["is_partisan"].to_s.downcase == "true" ? 1 : 0 if row["is_partisan"].class != Integer
      data_hash["is_unexpired"] = is_unexpired
      data_hash["has_primary"] = has_primary
      data_hash["is_partisan"] = is_partisan
      data_hash["vote_for"] = row["vote_for"]
      data_hash["term"] = row["term"]
      data_hash["run_id"] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      hash_array.push(data_hash)
      if hash_array.size == insertion_size
        keeper.insert_candidate_2020_xlsx_data(hash_array)
        hash_array = []
      end
    end
    keeper.insert_candidate_2020_xlsx_data(hash_array) unless hash_array.empty?
  end
  
  def get_candidate_2021_data(file, run_id)
    insertion_size = 1000
    hash_array = []
    header = file.first
    file.each do |row|
      next if row == header
      data_hash = {}
      data_hash["election_dt"] = DateTime.strptime(row["election_dt"] , "%m/%d/%Y").to_date 
      data_hash["county_name"] = row["county_name"]
      data_hash["contest_name"] = row["contest_name"]
      data_hash["name_on_ballot"] = row["name_on_ballot"]
      data_hash["first_name"] = row["first_name"]
      data_hash["middle_name"] = row["middle_name"]
      data_hash["last_name"] = row["last_name"]
      data_hash["name_suffix_lbl"] = row["name_suffix_lbl"]
      data_hash["nick_name"] = row["nick_name"]
      data_hash["party_contest"] = row["party_contest"]
      data_hash["party_candidate"] = row["party_candidate"]
      data_hash["candidacy_dt"] = DateTime.strptime(row["candidacy_dt"] , "%m/%d/%Y").to_date 
      is_unexpired = row["is_unexpired"].to_s.downcase == "true" ? 1 : 0 if row["is_unexpired"].class != Integer
      has_primary = row["has_primary"].to_s.downcase == "true" ? 1 : 0 if row["has_primary"].class != Integer
      is_partisan = row["is_partisan"].to_s.downcase == "true" ? 1 : 0 if row["is_partisan"].class != Integer
      data_hash["is_unexpired"] = is_unexpired
      data_hash["has_primary"] = has_primary
      data_hash["is_partisan"] = is_partisan
      data_hash["vote_for"] = row["vote_for"]
      data_hash["term"] = row["term"]
      data_hash["street_address"] = row["street_address"]
      data_hash["city"] = row["city"]
      data_hash["state"] = row["state"]
      data_hash["zip_code"] = row["zip_code"]
      data_hash["phone"] = row["phone"]
      data_hash["office_phone"] = row["office_phone"]
      data_hash["business_phone"] = row["business_phone"]
      data_hash["campaign_email"] = row["campaign_email"]
      data_hash["run_id"] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      hash_array.push(data_hash)
      if hash_array.size == insertion_size
        keeper.insert_candidate_2021_xlsx_data(hash_array)
        hash_array = []
      end
    end
    keeper.insert_candidate_2021_xlsx_data(hash_array) unless hash_array.empty?
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values do |value|
      value = value.strip unless value.nil? or value.class != String
      value.to_s.squish.empty? ? nil : value
    end
  end

end
