# frozen_string_literal: true

def ct_put_all_in_db(case_detail, document_list)
  info = case_detail.info
  case_id = info[:case_id]

  begin
    CtSaacCaseInfo.insert(info) unless info.nil?

    activities = document_list.ct_case_activities unless document_list.ct_case_activities_nil?
    CtSaacCaseActivities.insert_all(activities) unless activities.nil?

    parties = case_detail.ct_case_parties unless case_detail.ct_case_parties_nil?
    CtSaacCaseParty.insert_all(parties) unless parties.nil?

    additional_info = case_detail.ct_case_additional_info unless case_detail.ct_case_additional_info_nil?
    CtSaacCaseAdditionalInfo.insert(additional_info) unless additional_info.nil?
  rescue => e
    CtSaacCaseInfo.where(case_id: case_id).destroy_all
    CtSaacCaseActivities.where(case_id: case_id).destroy_all
    CtSaacCaseParty.where(case_id: case_id).destroy_all
    CtSaacCaseAdditionalInfo.where(case_id: case_id).destroy_all
  end
end

def ct_put_all_in_db_sql(case_detail, document_list)
  info = case_detail.ct_case_info

  begin
    return nil if info.nil? || info.empty?

    sql_case_info_insert(info.first) unless info.nil? || info.empty?

    activities = document_list.ct_case_activities unless document_list.ct_case_activities_nil?
    sql_case_activities_insert_all(activities) unless activities.nil? || activities.empty?

    parties = case_detail.ct_case_parties unless case_detail.ct_case_parties_nil?
    sql_case_party_insert_all(parties) unless parties.nil? || parties.empty?

    additional_info = case_detail.ct_case_additional_info unless case_detail.ct_case_additional_info_nil?
    sql_case_add_info_insert_all(additional_info) unless additional_info.nil? || additional_info.empty?
  rescue => e
    # CtSaacCaseInfo.where(case_id: case_id).destroy_all
    # CtSaacCaseActivities.where(case_id: case_id).destroy_all
    # CtSaacCaseParty.where(case_id: case_id).destroy_all
    # CtSaacCaseAdditionalInfo.where(case_id: case_id).destroy_all
  end
end

def connect_to_db(database = :us_court_cases)
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end

def sql_case_info_insert(info)
  client = connect_to_db

  case_filed_date = info[:case_filed_date].to_s.blank? ? '0000-00-00' : info[:case_filed_date]

  begin
    query = "INSERT IGNORE INTO us_court_cases.ct_saac_case_info
             (
               court_id, case_id, case_name, case_filed_date, case_type, case_description, disposition_or_status,
               status_as_of_date, judge_name, data_source_url, touched_run_id, deleted,
               md5_hash, run_id
             )
             VALUES
             (
               #{info[:court_id]}, '#{info[:case_id]}', '#{info[:case_name].to_s.gsub("'", "''")}',
               '#{case_filed_date}', '#{info[:case_type].to_s.gsub("'", "''")}', '#{info[:case_description].to_s.gsub("'", "''")}',
               '#{info[:disposition_or_status]}', '#{info[:status_as_of_date]}',
               '#{info[:judge_name].to_s.gsub("'", "''")}', '#{info[:data_source_url]}', 0, 0,
               '#{info[:md5_hash]}', #{info[:run_id]}
             )"
    client.query(query)
  rescue StandardError => e
    # Hamster.report(to: 'dmitiry.suschinsky', message: "#350 INFO - exception:\n #{e}")
  ensure
    client.close
  end
end

def sql_case_add_info_insert_all(rows)
  client = connect_to_db

  begin
    rows.each do |add_info|
      lower_judgement_date = add_info[:lower_judgement_date].to_s.blank? ? '0000-00-00' : add_info[:lower_judgement_date]
      query = "INSERT IGNORE INTO us_court_cases.ct_saac_case_additional_info
             (
               court_id, case_id, lower_court_name, lower_case_id, lower_judge_name, lower_judgement_date, lower_link, disposition,
               data_source_url, touched_run_id, deleted, md5_hash, run_id
             )
             VALUES
             (
               #{add_info[:court_id]}, '#{add_info[:case_id]}', '#{add_info[:lower_court_name].to_s.gsub("'", "''")}',
               '#{add_info[:lower_case_id]}', '#{add_info[:lower_judge_name].to_s.gsub("'", "''")}',
               '#{lower_judgement_date}',
               '#{add_info[:lower_link]}', '#{add_info[:disposition].to_s.gsub("'", "''")}',
               '#{add_info[:data_source_url]}', 0, 0,
               '#{add_info[:md5_hash]}', '#{add_info[:run_id]}'
             )"
      client.query(query)
    end

  rescue StandardError => e
    # Hamster.report(to: 'dmitiry.suschinsky', message: "#350 ADD - exception:\n #{error_msg}")
  ensure
    client.close
  end
end

def sql_case_activities_insert_all(activities)
  client = connect_to_db

  begin
    activities.each do |row|
      activity_date = row[:activity_date].blank? ? 'NULL' : "\'#{row[:activity_date]}\'"
      query = "INSERT IGNORE INTO us_court_cases.ct_saac_case_activities
             (
               court_id, case_id, activity_date, activity_desc, activity_type, file, activity_pdf, data_source_url,
               touched_run_id, deleted, md5_hash, run_id
             )
             VALUES
             (
               #{row[:court_id]}, '#{row[:case_id]}', #{activity_date},
               '#{row[:activity_desc].to_s.gsub("'", "''")}', '#{row[:activity_type].to_s.gsub("'", "''")}', '#{row[:file]}', '#{row[:activity_pdf]}',
               '#{row[:data_source_url]}', 0, 0,'#{row[:md5_hash]}', #{row[:run_id]}
             )"
      client.query(query)
    end
  rescue StandardError => e
    # Hamster.report(to: 'dmitiry.suschinsky', message: "#350 ACTIVITIES - exception:\n #{error_msg}")
  ensure
    client.close
  end
end

def sql_case_party_insert_all(parties)
  client = connect_to_db

  begin
    parties.each do |row|
      query = "INSERT IGNORE INTO us_court_cases.ct_saac_case_party
             (
               court_id, case_id, is_lawyer, party_name, party_type, party_law_firm,
               party_address, party_city, party_state, party_zip, party_description, data_source_url,
               touched_run_id, deleted, md5_hash, run_id
             )
             VALUES
             (
               #{row[:court_id]}, '#{row[:case_id]}', #{row[:is_lawyer]}, '#{row[:party_name].to_s.gsub("'", "''")}',
               '#{row[:party_type].to_s.gsub("'", "''")}', '#{row[:party_law_firm].to_s.gsub("'", "''")}', '#{row[:party_address]}',
               '#{row[:party_city]}', '#{row[:party_state]}', '#{row[:party_zip]}',
               '#{row[:party_description].to_s.gsub("'", "''")}',
               '#{row[:data_source_url]}', 0, 0, '#{row[:md5_hash]}', '#{row[:run_id]}'
             )"
      client.query(query)

    end
  rescue StandardError => e
    # Hamster.report(to: 'dmitiry.suschinsky', message: "#350 PARTIES - exception:\n #{error_msg}")
  ensure
    client.close
  end
end
