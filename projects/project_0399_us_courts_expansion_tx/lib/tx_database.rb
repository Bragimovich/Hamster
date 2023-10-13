# frozen_string_literal: true
def connect_to_db(database = :us_court_cases)
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end

def tx_put_all_in_db(case_detail, document_list, tx_case_info)
  case_id = tx_case_info[:case_id]

  begin
    TxSaacCaseInfo.insert(tx_case_info) unless tx_case_info.nil?

    tx_case_activities = document_list.tx_case_activities unless document_list.tx_case_activities_nil?
    TxSaacCaseActivities.insert_all(tx_case_activities) unless tx_case_activities.nil?

    tx_case_parties = case_detail.tx_case_parties unless case_detail.tx_case_parties_nil?
    TxSaacCaseParty.insert_all(tx_case_parties) unless tx_case_parties.nil?

    tx_case_additional_info = case_detail.tx_case_additional_info unless case_detail.tx_case_additional_info_nil?
    TxSaacCaseAdditionalInfo.insert(tx_case_additional_info) unless tx_case_additional_info.nil?
  rescue => e
    TxSaacCaseInfo.where(case_id: case_id).destroy_all
    TxSaacCaseActivities.where(case_id: case_id).destroy_all
    TxSaacCaseParty.where(case_id: case_id).destroy_all
    TxSaacCaseAdditionalInfo.where(case_id: case_id).destroy_all
  end
end

def tx_put_all_in_db_sql(case_detail, document_list, tx_case_info)
  case_id = tx_case_info[:case_id]

  begin
    sql_case_info_insert(tx_case_info.first) unless tx_case_info.nil?

    tx_case_activities = document_list.tx_case_activities unless document_list.tx_case_activities_nil?
    sql_case_activities_insert_all(tx_case_activities) unless tx_case_activities.nil? || tx_case_activities.size.zero?

    tx_case_parties = case_detail.tx_case_parties unless case_detail.tx_case_parties_nil?
    sql_case_party_insert_all(tx_case_parties) unless tx_case_parties.nil? || tx_case_parties.size.zero?

    tx_case_additional_info = case_detail.tx_case_additional_info unless case_detail.tx_case_additional_info_nil?
    sql_case_add_info_insert(tx_case_additional_info.first) unless tx_case_additional_info.nil? || tx_case_additional_info.size.zero?

  rescue => e
    TxSaacCaseInfo.where(case_id: case_id).destroy_all
    TxSaacCaseActivities.where(case_id: case_id).destroy_all
    TxSaacCaseParty.where(case_id: case_id).destroy_all
    TxSaacCaseAdditionalInfo.where(case_id: case_id).destroy_all
  end
end

def sql_case_info_insert(ct_case_info)
  client = connect_to_db

  begin
    query = "INSERT INTO us_court_cases.tx_saac_case_info
             (
                court_id, case_id, case_name, case_filed_date, case_type, case_description, disposition_or_status,
                status_as_of_date, judge_name, data_source_url, touched_run_id,
                deleted, md5_hash, run_id, lower_court_id, lower_case_id
             )
             VALUES
             (
               #{ct_case_info[:court_id]}, '#{ct_case_info[:case_id]}', '#{ct_case_info[:case_name]}',
               STR_TO_DATE(REPLACE('#{ct_case_info[:case_filed_date]}', '/', '-'), '%Y-%m-%d'),
               '#{ct_case_info[:case_type]}', '#{ct_case_info[:case_description]}', '#{ct_case_info[:disposition_or_status]}',
               '#{ct_case_info[:status_as_of_date]}',
               '#{ct_case_info[:judge_name]}', '#{ct_case_info[:data_source_url]}',
               0, 0, '#{ct_case_info[:md5_hash]}', #{ct_case_info[:run_id]},
               #{ct_case_info[:lower_court_id].nil? ? 0 : ct_case_info[:lower_court_id]}, '#{ct_case_info[:lower_case_id]}'
             )"
    client.query(query)
  rescue StandardError => e
    p e
    p e.backtrace
  ensure
    client.close
  end
end

def sql_case_activities_insert_all(ct_case_activities)
  client = connect_to_db

  begin
    ct_case_activities.each do |row|
      activity_date = row[:activity_date].blank? ? 'NULL' : "\'#{row[:activity_date]}\'"
      query = "INSERT INTO us_court_cases.tx_saac_case_activities
             (
                court_id, case_id, activity_date, activity_desc, activity_type,
                file, activity_pdf, data_source_url, touched_run_id, deleted,
                md5_hash, run_id
             )
             VALUES
             (
               #{row[:court_id]}, '#{row[:case_id]}', #{activity_date},
               '#{row[:activity_desc]}', '#{row[:activity_type]}', '#{row[:file]}', '#{row[:activity_pdf]}',
               '#{row[:data_source_url]}', 0, 0,'#{row[:md5_hash]}', #{row[:run_id]}
             )"
      client.query(query)
    end
  rescue StandardError => e
    p e
    p e.backtrace
  ensure
    client.close
  end
end

def sql_case_party_insert_all(ct_case_parties)
  client = connect_to_db

  begin
    ct_case_parties.each do |row|
      query = "INSERT INTO us_court_cases.tx_saac_case_party
             (
               court_id, case_id, is_lawyer, party_name, party_type, party_law_firm,
               party_address, party_city, party_state, party_zip, party_description,
               data_source_url, touched_run_id, deleted, md5_hash, run_id
             )
             VALUES
             (
               #{row[:court_id]}, '#{row[:case_id]}', #{row[:is_lawyer]}, '#{row[:party_name].gsub("'", "''")}',
               '#{row[:party_type]}', '#{row[:party_law_firm]}', '#{row[:party_address]}',
               '#{row[:party_city]}', '#{row[:party_state]}', '#{row[:party_zip]}',
               '#{row[:party_description]}',
               '#{row[:data_source_url]}', 0, 0, '#{row[:md5_hash]}', '#{row[:run_id]}'
             )"
      client.query(query)
    end
  rescue StandardError => e
    p e
    p e.backtrace
  ensure
    client.close
  end
end

def sql_case_add_info_insert(ct_case_add_info)
  client = connect_to_db

  begin
    query = "INSERT INTO us_court_cases.tx_saac_case_additional_info
             (
               court_id, case_id, lower_court_name, lower_case_id, lower_judge_name,
               lower_judgement_date, lower_link, disposition, data_source_url, created_by,
               touched_run_id, deleted, md5_hash, run_id
             )
             VALUES
             (
               #{ct_case_add_info[:court_id]}, '#{ct_case_add_info[:case_id]}', '#{ct_case_add_info[:lower_court_name]}',
               '#{ct_case_add_info[:lower_case_id]}', '#{ct_case_add_info[:lower_judge_name]}',
               STR_TO_DATE(REPLACE('#{ct_case_add_info[:lower_judgement_date]}', '/', '-'), '%m-%d-%Y'),
               '#{ct_case_add_info[:lower_link]}', '#{ct_case_add_info[:disposition]}',
               '#{ct_case_add_info[:data_source_url]}', 0, 0,
               '#{ct_case_add_info[:md5_hash]}', '#{ct_case_add_info[:run_id]}'
             )"

    client.query(query)
  rescue StandardError => e
  ensure
    client.close
  end
end

