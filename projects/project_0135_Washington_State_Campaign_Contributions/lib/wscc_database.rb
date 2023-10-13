# frozen_string_literal: true

def insert_all(rows)
  WSCC.insert_all(rows)
end

def existing_md5_hash(md5_hashes, run_id)
  existed_md5_hash = []
  existed_contributions = WSCC.where(md5_hash:md5_hashes)
  return [] if existed_contributions.empty?
  existed_contributions.each do |row|
    existed_md5_hash.push(row[:md5_hash])
    # row.touched_run_id = run_id
    # row.deleted = 0
    # row.save
  end
  existed_contributions.update_all(touched_run_id:run_id, deleted: 0)
  existed_md5_hash
end


def mark_deleted_rows(run_id)
  WSCC.connection.reconnect!
  deleted_rows = WSCC.where.not(touched_run_id:run_id)
  deleted_rows.update_all(deleted: 1)
end

def deleted_contribution_ids
  ids = []
  WSCC.where(deleted:1).each do |row|
    ids.push(row.contribution_id)
  end
  ids
end



def transfer_temp_to_general(run_id)
  ids = deleted_contribution_ids

  client = connect_to_db
  ids.in_groups(ids.size.quo(500).ceil, false).each do |divided_ids_list|
    query_delete = "DELETE FROM asure_cc.washington_state_campaign_contributions WHERE unique_source_id in (#{divided_ids_list.join(',')})"
    client.query(query_delete)
  end
  query_insert =
    "INSERT IGNORE INTO asure_cc.washington_state_campaign_contributions " \
            "(contributor_full_name, contributor_street, contributor_city, contributor_state, contributor_zip, " \
            "contributor_job_title, contributor_employer, contribution_amount, contribution_type, contribution_date, " \
            "committee_name, committee_party, committee_type, unique_source_id) " \
      "SELECT contributor_name, contributor_address, contributor_city, contributor_state, contributor_zip, " \
             "contributor_occupation, contributor_employer_name, amount, type, receipt_date, " \
             "filer_name, party, jurisdiction_type, contribution_id " \
        "FROM usa_raw.washington_state_campaign_contributions_csv " \
        "WHERE deleted=0 " \
            "AND contribution_id not in (SELECT unique_source_id from asure_cc.washington_state_campaign_contributions)"
  client.query(query_insert)
end


def connect_to_db
  Mysql2::Client.new(Storage[host: :db01, db: :usa_raw].except(:adapter).merge(symbolize_keys: true))
end


def insert_all_new(rows, type)
  db_model_wsc[type].insert_all(rows)
end

def wscc_insert(rows, type)
  db_model_wsc[type].insert(rows)
end

def wscc_update(contr_in_db, run_id)
  contr_in_db.update(touched_run_id:run_id, deleted:0)
end

def existed_row_by_md5(md5_hash,type)
  db_model_wsc[type].where(md5_hash:md5_hash)
end


def existing_md5_hash_new(md5_hashes, run_id, type)
  existed_md5_hash = []
  existed_contributions = db_model_wsc[type].where(md5_hash:md5_hashes)
  return [] if existed_contributions.empty?
  existed_contributions.each do |row|
    existed_md5_hash.push(row[:md5_hash])
    # row.touched_run_id = run_id
    # row.deleted = 0
    # row.save
  end
  existed_contributions.update_all(touched_run_id:run_id, deleted: 0)
  existed_md5_hash
end

def mark_deleted_rows_new(run_id, type)
  reconnect_db(type)
  deleted_rows = db_model_wsc[type].where.not(touched_run_id:run_id)
  deleted_rows.update_all(deleted: 1)
end

def reconnect_db(type)
  db_model_wsc[type].connection.reconnect!
end

def db_model_wsc
  {
    :contribute => WSCC,
    :expenditures => WSCE,
    :candidate => WSCandidates,
  }
end