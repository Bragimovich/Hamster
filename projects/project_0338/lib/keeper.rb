# frozen_string_literal: true

require_relative '../models/minnesota_campaign_finance_candidates'
require_relative '../models/minnesota_campaign_finance_committees'
require_relative '../models/minnesota_campaign_finance_parties'
require_relative '../models/minnesota_campaign_finance_runs'

class Keeper < Hamster::Harvester

  MAX_VALID_DELETED_COUNT = 500
  DB_RECONNECT_SLEEP = 5
  SCRAPE_DEVELOPER_NAME = 'Muhammad Qasim'
  ROLE_TYPE_ARRAY = ['Chair', 'Deputy Treasurer', 'Treasurer', 'Depository']
  CONTRIBUTIONS_HEADERS = [
    "Recipient reg num",
    "Recipient",
    "Recipient type",
    "Recipient subtype",
    "Amount",
    "Receipt date",
    "Year",
    "Contributor",
    "Contrib Reg Num",
    "Contrib type",
    "Receipt type",
    "In kind?",
    "In-kind descr",
    "Contrib zip",
    "Contrib Employer name"
  ]
  EXPENDITURES_HEADERS = [
    "Committee reg num",
    "Committee name",
    "Entity type",
    "Entity sub-type",
    "Vendor name",
    "Vendor address 1",
    "Vendor address 2",
    "Vendor city",
    "Vendor state",
    "Vendor zip",
    "Amount",
    "Unpaid amount",
    "Date",
    "Purpose",
    "Year",
    "Type",
    "In-kind descr",
    "In-kind?",
    "Affected committee name",
    "Affected committee reg num"
  ]

  def initialize
    super
    @run_object = safe_operation(MinnesotaCampaignFinanceRun) { |model| RunId.new(model) }
    @run_id = safe_operation(MinnesotaCampaignFinanceRun) { @run_object.run_id }
  end

  attr_reader :run_id

  def save_candidate?(candidate)
    need_to_save_candidate = false
    old_candidates = candidates_by_reg_ent_id(candidate['registered_entity_id'])
    return true if old_candidates.size.zero?
    old_candidates.each do |old_candidate|
      need_to_save_candidate = true if candidate_valid?(candidate, old_candidate)
    end
    logger.info need_to_save_candidate
    need_to_save_candidate
  end

  def insert_data_candidate(data_hash)
    safe_operation(MCFCandidates) { |model| model.insert(data_hash) } unless data_hash.empty?
    logger.info "------------------- INSERTED DATA -------------------"
  end

  def insert_data_committee(data_hash)
    safe_operation(MCFCommittees) { |model| model.insert(data_hash) } unless data_hash.empty?
    logger.info "------------------- INSERTED DATA -------------------"
  end

  def insert_data_party(data_hash)
    safe_operation(MCFParties) { |model| model.insert(data_hash) } unless data_hash.empty?
    logger.info "------------------- INSERTED DATA -------------------"
  end

  def load_tmp_csv(file_path, csv_type)
    validate_csv(file_path, csv_type)
    client = create_client_connection
    if csv_type.eql?('contributions')
      begin
        query = <<~SQL
          load data local infile '#{file_path}' into table minnesota_campaign_finance_tmp_contributions
          FIELDS TERMINATED BY ','
          OPTIONALLY ENCLOSED BY '\"'
          LINES TERMINATED BY '\n'
          IGNORE 1 LINES
          (registered_entity_id,
          committee_name,
          committee_type,
          committee_sub_type,
          cash_amount,
          @received_date,
          filing_year,
          contributor_full_name,
          contributor_reg_ent_id,
          contributor_type,
          contribution_type,
          in_kind_amount,
          in_kind_description,
          zip,
          contributor_employer_full_name,
          @created_by)
          SET received_date = STR_TO_DATE(@received_date,'%m/%d/%Y'),
          created_by = '#{SCRAPE_DEVELOPER_NAME}';
        SQL
        
        client.query('TRUNCATE table minnesota_campaign_finance_tmp_contributions;')
        client.query(query)

        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET data_source_url = 'https://cfb.mn.gov/reports-and-data/self-help/data-downloads/campaign-finance/';")
        client.query('UPDATE minnesota_campaign_finance_tmp_contributions SET created_at = updated_at WHERE created_at IS NULL;')

        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET committee_sub_type = NULL WHERE committee_sub_type = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET contributor_reg_ent_id = NULL WHERE contributor_reg_ent_id = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET contributor_full_name = NULL WHERE contributor_full_name = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET zip = NULL WHERE zip = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET in_kind_description = NULL WHERE in_kind_description = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_contributions SET contributor_employer_full_name = NULL WHERE contributor_employer_full_name = '';")
      rescue StandardError => e
       logger.error e
       logger.error e.backtrace
      ensure
        client.close
      end
    else
      begin
        query = <<~SQL
          load data local infile '#{file_path}' into table minnesota_campaign_finance_tmp_expenditures
          FIELDS TERMINATED BY ','
          OPTIONALLY ENCLOSED BY '\"'
          LINES TERMINATED BY '\n'
          IGNORE 1 LINES
          (registered_entity_id,
          reg_ent_full_name,
          registered_entity_type,
          registered_entity_subtype,
          vendor_name,
          vendor_address1,
          vendor_address2,
          vendor_city,
          vendor_state,
          vendor_zipcode,
          expenditure_amount,
          expenditure_unpaid_amount,
          @expenditure_date,
          purpose,
          filing_year,
          expenditure_type,
          in_kind_description,
          expenditure_in_kind,
          affected_name,
          affected_reg_num,
          @created_by)
          SET
          expenditure_date = STR_TO_DATE(@expenditure_date,'%m/%d/%Y'),
          created_by = '#{SCRAPE_DEVELOPER_NAME}';
        SQL
        client.query('TRUNCATE table minnesota_campaign_finance_tmp_expenditures;')
        client.query(query)
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET data_source_url = 'https://cfb.mn.gov/reports-and-data/self-help/data-downloads/campaign-finance/';")
        client.query('UPDATE minnesota_campaign_finance_tmp_expenditures SET created_at = updated_at WHERE created_at IS NULL;')
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET registered_entity_subtype = NULL WHERE registered_entity_subtype = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET vendor_address1 = NULL WHERE vendor_address1 = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET vendor_address2 = NULL WHERE vendor_address2 = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET vendor_city = NULL WHERE vendor_city = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET vendor_state = NULL WHERE vendor_state = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET vendor_zipcode = NULL WHERE vendor_zipcode = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET purpose = NULL WHERE purpose = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET expenditure_in_kind = NULL WHERE expenditure_in_kind = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET affected_name = NULL WHERE affected_name = '';")
        client.query("UPDATE minnesota_campaign_finance_tmp_expenditures SET affected_reg_num = NULL WHERE affected_reg_num = '';")
      rescue Exception => e
        logger.error e
        logger.error e.backtrace
      ensure
        client.close
      end
    end
  end

  def generate_md5_on_temp_csv_table(csv_type)
    if csv_type.eql?('contributions')
      begin
        client = create_client_connection
        query = <<~SQL
          update minnesota_campaign_finance_tmp_contributions
          set md5_hash = md5(concat(IFNULL(registered_entity_id, ''),
          IFNULL(committee_name, ''),
          IFNULL(committee_type, ''),
          IFNULL(committee_sub_type, ''),
          IFNULL(cash_amount, ''),
          IFNULL(received_date, ''),
          IFNULL(filing_year, ''),
          IFNULL(contributor_full_name, ''),
          IFNULL(contributor_reg_ent_id, ''),
          IFNULL(contributor_type, ''),
          IFNULL(contribution_type, ''),
          IFNULL(in_kind_amount, ''),
          IFNULL(in_kind_description, ''),
          IFNULL(zip, ''),
          IFNULL(contributor_employer_full_name, '')));
        SQL
        client.query(query)
        logger.info '###Generate md5 to contributions - COMPLETED###'
      ensure
        client.close
      end
    else
      begin
        client = create_client_connection
        query = <<~SQL
          update minnesota_campaign_finance_tmp_expenditures
          set md5_hash = md5(concat(IFNULL(registered_entity_id, ''),
          IFNULL(reg_ent_full_name, ''),
          IFNULL(registered_entity_type, ''),
          IFNULL(registered_entity_subtype, ''),
          IFNULL(vendor_name, ''),
          IFNULL(vendor_address1, ''),
          IFNULL(vendor_address2, ''),
          IFNULL(vendor_city, ''),
          IFNULL(vendor_state, ''),
          IFNULL(vendor_zipcode, ''),
          IFNULL(expenditure_amount, ''),
          IFNULL(expenditure_unpaid_amount, ''),
          IFNULL(expenditure_date, ''),
          IFNULL(purpose, ''),
          IFNULL(filing_year, ''),
          IFNULL(expenditure_type, ''),
          IFNULL(in_kind_description, ''),
          IFNULL(expenditure_in_kind, ''),
          IFNULL(affected_name, ''),
          IFNULL(affected_reg_num, '')));
        SQL
        client.query(query)
        logger.info '###Generate md5 to expenditures - COMPLETED###'
      ensure
        client.close
      end
    end
  end

  def clear_csv_touched(csv_type)
      begin
        client = create_client_connection
        query = <<~SQL
          update minnesota_campaign_finance_#{csv_type}_csv
          set touched_run_id = NULL where touched_run_id = 1;
        SQL
        client.query(query)
        logger.info "###Clear #{csv_type} touched_run_id - COMPLETED###"
      ensure
        client.close
      end
  end

  def set_csv_touched(start_date, end_date, csv_type)
    csv_date = csv_type.eql?('contributions') ? 'received_date' : 'expenditure_date'
    begin
      client = create_client_connection
      query = <<~SQL
        update minnesota_campaign_finance_#{csv_type}_csv t
        join (select m.md5_hash from
        (select md5_hash, count(*) as md5_count from minnesota_campaign_finance_#{csv_type}_csv
        where deleted_at is null AND #{csv_date} BETWEEN '#{start_date}' AND '#{end_date}' group by md5_hash) m
        join (select md5_hash, count(*) as md5_count_upload from minnesota_campaign_finance_tmp_#{csv_type} WHERE #{csv_date} BETWEEN '#{start_date}' AND '#{end_date}' group by md5_hash) u
        on m.md5_hash = u.md5_hash and m.md5_count = u.md5_count_upload) s
        on t.md5_hash = s.md5_hash
        set touched_run_id = 1;
      SQL
      client.query(query)
      logger.info "###Set #{csv_type} touched_run_id #{start_date} -- #{end_date} - COMPLETED###"
    ensure
      client.close
    end
  end

  def set_csv_deleted(csv_type)
    begin
      client = create_client_connection
      query1 = <<~SQL
        select count(*) from minnesota_campaign_finance_#{csv_type}_csv
        WHERE deleted_at IS NULL AND (touched_run_id != 1 OR touched_run_id IS NULL)
      SQL
      result = client.query(query1)
      raise "Too much deleted #{csv_type}" if result.first["count(*)"].to_i > MAX_VALID_DELETED_COUNT
      query = <<~SQL
        UPDATE minnesota_campaign_finance_#{csv_type}_csv SET deleted_at = NOW()
        WHERE deleted_at IS NULL AND (touched_run_id != 1 OR touched_run_id IS NULL);
      SQL
      client.query(query)
      logger.info "###Set #{csv_type} deleted - COMPLETED###"
    ensure
      client.close
    end
  end

  def copy_new_csv(csv_type)
    if csv_type.eql?('contributions')
      begin
        client = create_client_connection
        query = <<~SQL
          delete from minnesota_campaign_finance_tmp_contributions
          where md5_hash in (select md5_hash from minnesota_campaign_finance_contributions_csv where deleted_at is null and touched_run_id = 1);
        SQL
        client.query(query)
        query2 = <<~SQL
          INSERT INTO minnesota_campaign_finance_contributions_csv
            (data_source_url,
            candidate_id,
            filer,
            filing_year,
            candidate_first_name,
            candidate_last_name,
            candidate_address,
            candidate_party,
            candidate_jurisdiction,
            site_source_candidate_id,
            committee_name,
            committee_type,
            committee_sub_type,
            committee_address,
            committee_party,
            registered_entity_id,
            source_candidate_id,
            contributor_id,
            contributor_reg_ent_id,
            contributor_full_name,
            contributors_first_name,
            contributors_last_name,
            contributor_type,
            address,
            city,
            state,
            zip,
            pac_affiliation,
            occupation,
            employer,
            received_date,
            contribution_type,
            cash_amount,
            in_kind_amount,
            in_kind_description,
            employer_master_name_id,
            contributor_employer_full_name,
            created_by,
            md5_hash)
            SELECT
            data_source_url,
            candidate_id,
            filer,
            filing_year,
            candidate_first_name,
            candidate_last_name,
            candidate_address,
            candidate_party,
            candidate_jurisdiction,
            site_source_candidate_id,
            committee_name,
            committee_type,
            committee_sub_type,
            committee_address,
            committee_party,
            registered_entity_id,
            source_candidate_id,
            contributor_id,
            contributor_reg_ent_id,
            contributor_full_name,
            contributors_first_name,
            contributors_last_name,
            contributor_type,
            address,
            city,
            state,
            zip,
            pac_affiliation,
            occupation,
            employer,
            received_date,
            contribution_type,
            cash_amount,
            in_kind_amount,
            in_kind_description,
            employer_master_name_id,
            contributor_employer_full_name,
            created_by,
            md5_hash
            FROM minnesota_campaign_finance_tmp_contributions;
        SQL
        client.query(query2)
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET in_kind_description = NULL WHERE in_kind_description = '';")
        logger.info '###Copy new contributions - COMPLETED###'
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET `created_at` = '#{Date.today.strftime("%Y-%m-%d")}' WHERE `created_at` IS NULL;")
        logger.info 'UPDATED === created_at ==='
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET `last_scrape_date` = '#{Date.today.strftime("%Y-%m-%d")}' WHERE `last_scrape_date` IS NULL;")
        logger.info 'UPDATED === last_scrape_date ==='
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET `next_scrape_date` = '#{Date.today.next_day.strftime("%Y-%m-%d")}' WHERE `next_scrape_date` IS NULL;")
        logger.info 'UPDATED === next_scrape_date ==='
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET `expected_scrape_frequency` = 'daily' WHERE `expected_scrape_frequency` IS NULL;")
        logger.info 'UPDATED === expected_scrape_frequency ==='
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET `dataset_name_prefix` = 'minnesota_campaign_finance' WHERE `dataset_name_prefix` IS NULL;")
        logger.info 'UPDATED === dataset_name_prefix ==='
        client.query("UPDATE minnesota_campaign_finance_contributions_csv SET `scrape_status` = 'live' WHERE `scrape_status` IS NULL;")
        logger.info 'UPDATED === scrape_status ==='
      ensure
        client.close
      end
    else   
      begin
        client = create_client_connection
        query = <<~SQL
          delete from minnesota_campaign_finance_tmp_expenditures
          where md5_hash in (select md5_hash from minnesota_campaign_finance_expenditures_csv where deleted_at is null and touched_run_id = 1);
        SQL
        client.query(query)
        query2 = <<~SQL
          INSERT INTO minnesota_campaign_finance_expenditures_csv
            (data_source_url,
            registered_entity_id,
            reg_ent_full_name,
            registered_entity_type,
            registered_entity_subtype,
            vendor_name,
            vendor_master_name_id,
            vendor_address1,
            vendor_address2,
            vendor_city,
            vendor_state,
            vendor_zipcode,
            expenditure_amount,
            expenditure_unpaid_amount,
            expenditure_date,
            purpose,
            filing_year,
            expenditure_type,
            in_kind_description,
            expenditure_in_kind,
            affected_name,
            affected_reg_num,
            created_by,
            md5_hash)
            SELECT
            data_source_url,
            registered_entity_id,
            reg_ent_full_name,
            registered_entity_type,
            registered_entity_subtype,
            vendor_name,
            vendor_master_name_id,
            vendor_address1,
            vendor_address2,
            vendor_city,
            vendor_state,
            vendor_zipcode,
            expenditure_amount,
            expenditure_unpaid_amount,
            expenditure_date,
            purpose,
            filing_year,
            expenditure_type,
            in_kind_description,
            expenditure_in_kind,
            affected_name,
            affected_reg_num,
            created_by,
            md5_hash
            FROM minnesota_campaign_finance_tmp_expenditures;
        SQL
        client.query(query2)
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET in_kind_description = NULL WHERE in_kind_description = '';")
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET vendor_name = NULL WHERE vendor_name = '';")
        logger.info '###Copy new expenditures - COMPLETED###'
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET `created_at` = '#{Date.today.strftime("%Y-%m-%d")}' WHERE `created_at` IS NULL;")
        logger.info 'UPDATED === created_at ==='
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET `last_scrape_date` = '#{Date.today.strftime("%Y-%m-%d")}' WHERE `last_scrape_date` IS NULL;")
        logger.info 'UPDATED === last_scrape_date ==='
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET `next_scrape_date` = '#{Date.today.next_day.strftime("%Y-%m-%d")}' WHERE `next_scrape_date` IS NULL;")
        logger.info 'UPDATED === next_scrape_date ==='
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET `expected_scrape_frequency` = 'daily' WHERE `expected_scrape_frequency` IS NULL;")
        logger.info 'UPDATED === expected_scrape_frequency ==='
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET `dataset_name_prefix` = 'minnesota_campaign_finance' WHERE `dataset_name_prefix` IS NULL;")
        logger.info 'UPDATED === dataset_name_prefix ==='
        client.query("UPDATE minnesota_campaign_finance_expenditures_csv SET `scrape_status` = 'live' WHERE `scrape_status` IS NULL;")
        logger.info 'UPDATED === scrape_status ==='
      ensure
        client.close
      end
    end
  end

  def validate_result(csv_type)
    begin
      client = create_client_connection
      query = <<~SQL
        select count(*) from minnesota_campaign_finance_#{csv_type}_csv
        where deleted_at = '#{Date.today.strftime("%Y-%m-%d")}';
      SQL
      result = client.query(query)
      raise "Too much deleted #{csv_type}" if result.first["count(*)"].to_i > MAX_VALID_DELETED_COUNT
    ensure
      client.close
    end
  end

  def update_touch_run_id(md5_hash_array, type)
    if type == "candidate"
      model = MCFCandidates
    elsif type == "pcf"
      model = MCFCommittees
    elsif type == "party"
      model = MCFParties
    end
    model.where(:md5_hash => md5_hash_array).update_all(:touched_run_id => run_id)
  end

  def mark_as_deleted(md5_hash_array, type)
    if type == "candidate"
      model = MCFCandidates
    elsif type == "pcf"
      model = MCFCommittees
    elsif type == "party"
      model = MCFParties
    end
    model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    safe_operation(MinnesotaCampaignFinanceRun) { @run_object.finish }
  end

  private
  
  def candidates_by_reg_ent_id(reg_ent_id)
    safe_operation(MCFCandidates) { |model| model.where(registered_entity_id: reg_ent_id) }
  end

  def candidate_valid?(candidate, old_candidate)
    return false if candidate['registered_entity_id'].nil?
    return false if candidate['committee_full_name'].nil?
    return false if candidate['candidate_full_name'].nil?

    return false if candidate['registered_entity_id'] == ''
    return false if candidate['committee_full_name'] == ''
    return false if candidate['candidate_full_name'] == ''

    return false if candidate['registered_entity_id'] == old_candidate.registered_entity_id &&
        candidate['committee_full_name'] == old_candidate.committee_full_name &&
        candidate['candidate_full_name'] == old_candidate.candidate_full_name
        update_candidate_as_deleted(old_candidate)
    return true
  end

  def update_candidate_as_deleted(old_candidate)
    safe_operation(MCFCandidates) { |model| model.update(old_candidate.id, :deleted_at => Date.today) } if old_candidate.deleted_at.nil?
  end

  def validate_csv(file_path, csv_type)
    file = File.read(file_path).encode!('UTF-8', 'UTF-8', invalid: :replace)
    csv_file = CSV.parse(file)
    if csv_type.eql?('contributions')
      raise 'Contributions columns doesn\'t match' unless csv_file.first.map{|e|e.gsub("+AC0-", "-")} == CONTRIBUTIONS_HEADERS
    else
      raise 'Expenditures columns doesn\'t match' unless csv_file.first.map{|e|e.gsub("+AC0-", "-")} == EXPENDITURES_HEADERS
    end
  end

  def create_client_connection
    1.upto(100) do
      begin
        return Mysql2::Client.new(Storage[host: :db01, db: :usa_fin_cc_raw])
      rescue Exception => e
       logger.error e
       logger.error e.backtrace
      end
      sleep DB_RECONNECT_SLEEP
    end
    raise "Unable create client database connection"
  end
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error "#{e.class}"
        logger.error "Reconnect!"
        sleep 100
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end
