# frozen_string_literal: true

require_relative '../models/connecticut_professional_licensing'
require_relative '../models/connecticut_professional_licensing_runs'
require_relative '../models/connecticut_professional_licensing_tmp'

class Keeper < Hamster::Scraper
  SCRAPE_DEV_NAME = 'Abdul Wahab'

  def initialize
    super
    # code to initialize object
  end

  def upload_csv_data(csv_file_path)

    begin
      query = <<~SQL
        TRUNCATE TABLE `connecticut_professional_licensing_tmp`;
      SQL

      safe_operation(ConnecticutProfessionalLicensingTmp) { |model| model.connection.execute(query) }
    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace
      raise e
    end

    begin
      query = <<~SQL
        LOAD DATA LOCAL INFILE '#{csv_file_path}'
        INTO TABLE `connecticut_professional_licensing_tmp`
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@credential_id,
         @name,
         @type,
         @business_name,
         @dba,
         @full_credential_code,
         @credential_type,
         @credential_number,
         @credential_sub_category,
         @credential,
         @status,
         @status_reason,
         @active,
         @issue_date,
         @effective_date,
         @expiration_date,
         @address,
         @city,
         @state,
         @zip,
         @record_refreshed_on)
        SET credential_id         = IF(@credential_id = '', NULL, @credential_id),
        name                      = IF(@name = '', NULL, @name),
        type                      = IF(@type = '', NULL, @type),
        business_name             = IF(@business_name = '', NULL, @business_name),
        dba                       = IF(@dba = '', NULL, @dba),
        full_credential_code      = IF(@full_credential_code = '', NULL, @full_credential_code),
        credential_type           = IF(@credential_type = '', NULL, @credential_type),
        credential_number         = IF(@credential_number = '', NULL, @credential_number),
        credential_sub_category   = IF(@credential_sub_category = '', NULL, @credential_sub_category),
        credential                = IF(@credential = '', NULL, @credential),
        status                    = IF(@status = '', NULL, @status),
        status_reason             = IF(@status_reason = '', NULL, @status_reason),
        active                    = IF(@active = '', NULL, @active),
        issue_date                = STR_TO_DATE(@issue_date,'%m/%d/%Y'),
        effective_date            = STR_TO_DATE(@effective_date,'%m/%d/%Y'),
        expiration_date           = STR_TO_DATE(@expiration_date,'%m/%d/%Y'),
        address                   = IF(@address = '', NULL, @address),
        city                      = IF(@city = '', NULL, @city),
        state                     = IF(@state = '', NULL, @state),
        zip                       = IF(@zip = '', NULL, @zip),
        record_refreshed_on       = STR_TO_DATE(@record_refreshed_on,'%m/%d/%Y'),
        data_source_url           = 'https://data.ct.gov/Business/State-Licenses-and-Credentials/ngch-56tr/data',
        created_by                = '#{SCRAPE_DEV_NAME}',
        scrape_frequency          = 'monthly',
        last_scrape_date          = '#{Time.now.strftime('%Y-%m-%d')}',
        next_scrape_date          = '#{1.month.since(Time.now)}',
        expected_scrape_frequency = 'monthly',
        dataset_name_prefix       = 'connecticut_professional_licensing',
        scrape_status             = 'live';
      SQL

      safe_operation(ConnecticutProfessionalLicensingTmp) { |model| model.connection.execute(query) }
    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace
      raise e
    end

  end

  def generate_md5_on_tmp_table
    begin
      query = <<~SQL
        UPDATE `connecticut_professional_licensing_tmp`
        SET md5_hash = md5(concat(IFNULL(credential_id, ''),
        IFNULL(name, ''),
        IFNULL(type, ''),
        IFNULL(business_name, ''),
        IFNULL(dba, ''),
        IFNULL(full_credential_code, ''),
        IFNULL(credential_type, ''),
        IFNULL(credential_number, ''),
        IFNULL(credential_sub_category, ''),
        IFNULL(credential, ''),
        IFNULL(status, ''),
        IFNULL(status_reason, ''),
        IFNULL(active, ''),
        IFNULL(issue_date, ''),
        IFNULL(effective_date, ''),
        IFNULL(expiration_date, ''),
        IFNULL(address, ''),
        IFNULL(city, ''),
        IFNULL(state, ''),
        IFNULL(zip, ''),
        IFNULL(record_refreshed_on, '')));
      SQL
      safe_operation(ConnecticutProfessionalLicensingTmp) { |model| model.connection.execute(query) }
    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace

      raise e
    end

    true
  end

  def mark_deleted_records
    begin
      ConnecticutProfessionalLicensing.where.not(md5_hash: ConnecticutProfessionalLicensingTmp.select(:md5_hash)).where(is_active: 1).update_all(is_active: 0, touched: 1, scrape_status: 'not live')

    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace

      raise e
    end

    true
  end


  def update_tmp_table
    begin
      table_a_ids = ConnecticutProfessionalLicensing.pluck(:md5_hash)

      batch_size = 1000

      # Delete records from TableB in batches
      table_a_ids.each_slice(batch_size) do |ids|
        ConnecticutProfessionalLicensingTmp.where(md5_hash: ids).delete_all
      end

    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace

      raise e
    end

    true
  end


  def copy_new_licenses
    begin

      query = <<~SQL
        INSERT INTO connecticut_professional_licensing
                    (credential_id,
                    name,
                    type,
                    business_name,
                    dba,
                    full_credential_code,
                    credential_type,
                    credential_number,
                    credential_sub_category,
                    credential,
                    status,
                    status_reason,
                    active,
                    issue_date,
                    effective_date,
                    expiration_date,
                    address,
                    city,
                    state,
                    zip,
                    record_refreshed_on,
                    data_source_url,
                    created_by,
                    created_at,
                    updated_at,
                    md5_hash,
                    scrape_frequency,
                    last_scrape_date,
                    next_scrape_date,
                    expected_scrape_frequency,
                    dataset_name_prefix,
                    scrape_status)
                    SELECT
                    credential_id,
                    name,
                    type,
                    business_name,
                    dba,
                    full_credential_code,
                    credential_type,
                    credential_number,
                    credential_sub_category,
                    credential,
                    status,
                    status_reason,
                    active,
                    issue_date,
                    effective_date,
                    expiration_date,
                    address,
                    city,
                    state,
                    zip,
                    record_refreshed_on,
                    data_source_url,
                    created_by,
                    created_at,
                    updated_at,
                    md5_hash,
                    scrape_frequency,
                    last_scrape_date,
                    next_scrape_date,
                    expected_scrape_frequency,
                    dataset_name_prefix,
                    scrape_status
                    FROM connecticut_professional_licensing_tmp;
      SQL

      safe_operation(ConnecticutProfessionalLicensing) { |model| model.connection.execute(query) }

    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace

      raise e
    end

  end

  def set_run_id
    run_object = RunId.new(ConnecticutProfessionalLicensingRuns)
    run_id = run_object.run_id
    current_date = Date.today
    ConnecticutProfessionalLicensing.where(last_scrape_date: current_date).update_all(run_id: run_id, touched_run_id: run_id)
    run_object.finish
  end

  def update_md5_hash
    batch_size = 1000

    # Retrieve the column names
    column_names = ConnecticutProfessionalLicensing.column_names

    # Calculate the total number of rows
    total_rows = ConnecticutProfessionalLicensing.count

    # Paginate through the rows and display them
    (0..total_rows).step(batch_size).each do |offset|
      rows = ConnecticutProfessionalLicensing.limit(batch_size).offset(offset)
      rows.each do |row|
        data_hash = {}
        data_hash[:credential_id] = row[:credential_id]
        data_hash[:name] = row[:name]
        data_hash[:type] = row[:type]
        data_hash[:dba] = row[:dba]
        data_hash[:full_credential_code] = row[:full_credential_code]
        data_hash[:credential_type] = row[:credential_type]
        data_hash[:credential_number] = row[:credential_number]
        data_hash[:credential_sub_category] = row[:credential_sub_category]
        data_hash[:credential] = row[:credential]
        data_hash[:status] = row[:status]
        data_hash[:status_reason] = row[:status_reason]
        data_hash[:active] = row[:active]
        data_hash[:issue_date] = row[:issue_date]
        data_hash[:effective_date] = row[:effective_date]
        data_hash[:address] = row[:address]
        data_hash[:city] = row[:city]
        data_hash[:state] = row[:state]
        data_hash[:zip] = row[:zip]
        data_hash[:record_refreshed_on] = row[:record_refreshed_on]
        md5_hash = MD5Hash.new(columns: data_hash.keys)
        md5_hash.generate(data_hash)
        data_hash[:md5_hash] = md5_hash.hash
        ConnecticutProfessionalLicensing.where(md5_hash: row[:md5_hash], credential_id: row[:credential_id]).update_all(md5_hash: data_hash[:md5_hash])
      end
    end
  end

  private

  def safe_operation(model, retries=0)
    begin
      yield(model)
    rescue *connection_error_classes => e
      Hamster.logger.debug e.full_message
      Hamster.logger.debug retries += 1
      Hamster.logger.debug '*' + "Reconnect!"+ '*'*77
      sleep retries*2
      model.connection.close rescue nil
      retry if retries < 15
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

  def create_client_connection
    1.upto(100) do
      begin
        return Mysql2::Client.new(Storage[host: :db01, db: :usa_raw])
        # return Mysql2::Client.new(Storage[host: :db09, db: :astorchak_test])
      rescue StandardError => e
        Hamster.logger.debug e
        Hamster.logger.debug e.backtrace
      end

      sleep DB_RECONNECT_SLEEP
    end

    raise 'Unable create client database connection'
  end

end
