# frozen_string_literal: true

require 'digest'

require_relative '../models/north_carolina_business_licenses'
require_relative '../models/north_carolina_business_licenses_new_business_csv'
require_relative '../models/north_carolina_business_licenses_new_business_csv_temp'

class Keeper < Hamster::Scraper
  SCRAPE_DEV_NAME = 'Zaid Akram'

  def upload_csv_data(csv_file_path)
    if csv_file_path.include?("NEW")
      client = create_client_connection

      begin
        query = <<~SQL
          LOAD DATA LOCAL INFILE '#{csv_file_path}'
          INTO TABLE `north_carolina_business_licenses_new_business_csv_temp`
          FIELDS TERMINATED BY ','
          OPTIONALLY ENCLOSED BY ''
          ESCAPED BY ''
          LINES  TERMINATED BY '\n'
          IGNORE 1 LINES
          (@corp_name,
          @date_formed,
          @citizenship,
          @type_license,
          @status,
          @sos_id,
          @registered_agent_name,
          @reg_office_address1,
          @reg_office_address2,
          @reg_office_city,
          @reg_office_state,
          @reg_office_zip,
          @reg_office_county,
          @pitem_id,
          @prin_address1,
          @prin_address2,
          @prin_city,
          @prin_state,
          @prin_zip,
          @prin_county)
          SET corp_name = IF(@corp_name = '', NULL, @corp_name),
          date_formed = STR_TO_DATE(@date_formed,'%m/%d/%Y %h:%i:%s %p'),
          citizenship = IF(@citizenship = '', NULL, @citizenship),
          type_license = IF(@type_license = '', NULL, @type_license),
          status = IF(@status = '', NULL, @status),
          sos_id = IF(@sos_id = '', NULL, @sos_id),
          registered_agent_name = IF(@registered_agent_name = '', NULL, @registered_agent_name),
          reg_office_address1 = IF(@reg_office_address1 = '', NULL, @reg_office_address1),
          reg_office_address2 = IF(@reg_office_address2 = '', NULL, @reg_office_address2),
          reg_office_city = IF(@reg_office_city = '', NULL, @reg_office_city),
          reg_office_state = IF(@reg_office_state = '', NULL, @reg_office_state),
          reg_office_zip = IF(@reg_office_zip = '', NULL, @reg_office_zip),
          reg_office_county = IF(@reg_office_county = '', NULL, @reg_office_county),
          pitem_id = IF(@pitem_id = '', NULL, @pitem_id),
          prin_address1 = IF(@prin_address1 = '', NULL, @prin_address1),
          prin_address2 = IF(@prin_address2 = '', NULL, @prin_address2),
          prin_city = IF(@prin_city = '', NULL, @prin_city),
          prin_state = IF(@prin_state = '', NULL, @prin_state),
          prin_zip = IF(@prin_zip = '', NULL, @prin_zip),
          prin_county = IF(@prin_county = '', NULL, @prin_county),
          data_source_url = 'https://www.sosnc.gov/online_services/search/by_title/_Business_Registration_Changes',
          scrape_dev_name = 'Zaid Akram',
          scrape_frequency = 'monthly',
          last_scrape_date = '#{Time.now.strftime('%Y-%m-%d')}',
          next_scrape_date = '#{1.month.since(Time.now)}',
          expected_scrape_frequency = 'monthly',
          dataset_name_prefix = 'north_carolina_business_licenses',
          scrape_status = 'live';
        SQL

        clear_column_names_query = <<~SQL
          DELETE FROM `north_carolina_business_licenses_new_business_csv_temp`
          WHERE corp_name = 'CorpName' AND
          citizenship = 'Citizenship' AND
          type_license = 'Type' AND
          status = 'Status' AND
          sos_id = 'SOSID' AND
          registered_agent_name = 'RegAgent' AND
          reg_office_address1 = 'RegAddr1' AND
          reg_office_address2 = 'RegAddr2' AND
          reg_office_city = 'RegCity' AND
          reg_office_state = 'RegState' AND
          reg_office_zip = 'RegZip' AND
          reg_office_county = 'RegCounty' AND
          pitem_id = 'PitemId' AND
          prin_address1 = 'PrinAddr1' AND
          prin_address2 = 'PrinAddr2' AND
          prin_city = 'PrinCity' AND
          prin_state = 'PrinState' AND
          prin_zip = 'PrinZip';
        SQL

        client.query(query)
        client.query(clear_column_names_query)
      rescue StandardError => e
        logger.debug e
        logger.debug e.backtrace
      ensure
        client.close
      end

    else  
      begin
        client = create_client_connection
        
        query_for_dissolved = <<~SQL
          LOAD DATA LOCAL INFILE '#{csv_file_path}'
          INTO TABLE `north_carolina_business_licenses_new_business_csv_temp`
          FIELDS TERMINATED BY ','
          OPTIONALLY ENCLOSED BY ''
          ESCAPED BY ''
          LINES  TERMINATED BY '\n'
          IGNORE 1 LINES
          (@corp_name,
          @date_dissolved,
          @citizenship,
          @type_license,
          @status,
          @sos_id,
          @reg_office_address1,
          @reg_office_address2,
          @reg_office_city,
          @reg_office_state,
          @reg_office_zip,
          @reg_office_county)
          SET corp_name = IF(@corp_name = '', NULL, @corp_name),
          date_dissolved = STR_TO_DATE(@date_dissolved,'%m/%d/%Y %h:%i:%s %p'),
          citizenship = IF(@citizenship = '', NULL, @citizenship),
          type_license = IF(@type_license = '', NULL, @type_license),
          status = IF(@status = '', NULL, @status),
          sos_id = IF(@sos_id = '', NULL, @sos_id),
          reg_office_address1 = IF(@reg_office_address1 = '', NULL, @reg_office_address1),
          reg_office_address2 = IF(@reg_office_address2 = '', NULL, @reg_office_address1),
          reg_office_city = IF(@reg_office_city = '', NULL, @reg_office_city),
          reg_office_state = IF(@reg_office_state = '', NULL, @reg_office_state),
          reg_office_zip = IF(@reg_office_zip = '', NULL, @reg_office_zip),
          reg_office_county = IF(@reg_office_county = '', NULL, @reg_office_county),
          data_source_url = 'https://www.sosnc.gov/online_services/search/by_title/_Business_Registration_Changes',
          scrape_dev_name = 'Zaid Akram',
          scrape_frequency = 'monthly',
          last_scrape_date = '#{Time.now.strftime('%Y-%m-%d')}',
          next_scrape_date = '#{1.month.since(Time.now)}',
          expected_scrape_frequency = 'monthly',
          dataset_name_prefix = 'north_carolina_business_licenses',
          scrape_status = 'live';
        SQL

        client.query(query_for_dissolved)
      rescue StandardError => e
        logger.debug e
        logger.debug e.backtrace
      ensure
        client.close
      end
    end
    File.delete(csv_file_path)
  end

  def update_records
    
    now = Date.today
    three_month_back = now << 3
    date_formed_var = three_month_back.to_s
    client = create_client_connection

    # Generating md5_hash
    generate_md5_hash = <<~SQL
      UPDATE north_carolina_business_licenses_new_business_csv_temp 
      SET md5_hash = MD5(CONCAT_WS(',', corp_name, date_formed, date_dissolved, citizenship, type_license, status, sos_id, registered_agent_name, reg_office_address1, reg_office_address2, reg_office_city, reg_office_state, reg_office_zip, reg_office_county, pitem_id, prin_address1, prin_address2, prin_city, prin_state, prin_zip, prin_county));
    SQL

    client.query(generate_md5_hash)

    # Mark touched records
    md5_hashs = NorthCarolinaBusinessLicensesNewBusinessCsvTemp.where("date_formed > '#{date_formed_var}'").pluck(:md5_hash)
    NorthCarolinaBusinessLicensesNewBusinessCsv.where("date_formed > '#{date_formed_var}' AND md5_hash IN (?)", md5_hashs).update_all("touched = touched + 1")
    NorthCarolinaBusinessLicensesNewBusinessCsvTemp.where(md5_hash: NorthCarolinaBusinessLicensesNewBusinessCsv.where('touched > 0').where("date_formed > '#{date_formed_var}'").pluck(:md5_hash))
    .delete_all
    
    # Mark deleted records
    md5_hashs = NorthCarolinaBusinessLicensesNewBusinessCsvTemp.where("date_formed > '#{date_formed_var}'").pluck(:md5_hash)
    NorthCarolinaBusinessLicensesNewBusinessCsv.where("date_formed > '#{date_formed_var}'").where.not(md5_hash: md5_hashs).where(touched: 0).update_all(deleted: 1)

    # Insert new records
    insert_new_records  = <<~SQL
      INSERT INTO north_carolina_business_licenses_new_business_csv (corp_name, date_formed, date_dissolved, citizenship, type_license, status, sos_id,
      registered_agent_name, reg_office_address1, reg_office_address2, reg_office_city, reg_office_state,
      reg_office_zip, reg_office_county, pitem_id, prin_address1, prin_address2, prin_city, prin_state,
      prin_zip, prin_county, scrape_dev_name, data_source_url, created_at, updated_at, scrape_frequency, last_scrape_date,
      next_scrape_date, expected_scrape_frequency, pl_gather_task_id, dataset_name_prefix, scrape_status,
      scraped_by_pitem_id, md5_hash, deleted, touched)
      SELECT north_carolina_business_licenses_new_business_csv_temp.corp_name, north_carolina_business_licenses_new_business_csv_temp.date_formed,north_carolina_business_licenses_new_business_csv_temp.date_dissolved, north_carolina_business_licenses_new_business_csv_temp.citizenship, north_carolina_business_licenses_new_business_csv_temp.type_license,
      north_carolina_business_licenses_new_business_csv_temp.status, north_carolina_business_licenses_new_business_csv_temp.sos_id,
      north_carolina_business_licenses_new_business_csv_temp.registered_agent_name, north_carolina_business_licenses_new_business_csv_temp.reg_office_address1, north_carolina_business_licenses_new_business_csv_temp.reg_office_address2, 
      north_carolina_business_licenses_new_business_csv_temp.reg_office_city, north_carolina_business_licenses_new_business_csv_temp.reg_office_state,
      north_carolina_business_licenses_new_business_csv_temp.reg_office_zip, north_carolina_business_licenses_new_business_csv_temp.reg_office_county, north_carolina_business_licenses_new_business_csv_temp.pitem_id, north_carolina_business_licenses_new_business_csv_temp.prin_address1, 
      north_carolina_business_licenses_new_business_csv_temp.prin_address2, north_carolina_business_licenses_new_business_csv_temp.prin_city, north_carolina_business_licenses_new_business_csv_temp.prin_state,
      north_carolina_business_licenses_new_business_csv_temp.prin_zip, north_carolina_business_licenses_new_business_csv_temp.prin_county, north_carolina_business_licenses_new_business_csv_temp.scrape_dev_name, north_carolina_business_licenses_new_business_csv_temp.data_source_url, 
      north_carolina_business_licenses_new_business_csv_temp.created_at, north_carolina_business_licenses_new_business_csv_temp.updated_at, north_carolina_business_licenses_new_business_csv_temp.scrape_frequency, north_carolina_business_licenses_new_business_csv_temp.last_scrape_date,
      north_carolina_business_licenses_new_business_csv_temp.next_scrape_date, north_carolina_business_licenses_new_business_csv_temp.expected_scrape_frequency, north_carolina_business_licenses_new_business_csv_temp.pl_gather_task_id, north_carolina_business_licenses_new_business_csv_temp.dataset_name_prefix,
      north_carolina_business_licenses_new_business_csv_temp.scrape_status,
      north_carolina_business_licenses_new_business_csv_temp.scraped_by_pitem_id, north_carolina_business_licenses_new_business_csv_temp.md5_hash, 0, 0
      FROM north_carolina_business_licenses_new_business_csv_temp
      WHERE md5_hash NOT IN (SELECT md5_hash FROM north_carolina_business_licenses_new_business_csv WHERE md5_hash IS NOT NULL AND deleted=0);
    SQL

    client.query(insert_new_records)
    
    # Free temp table
    free_temp_table = <<~SQL
      DELETE FROM north_carolina_business_licenses_new_business_csv_temp;
    SQL
    
    client.query(free_temp_table)

  end

  private

  def create_client_connection
    1.upto(100) do
      begin
        hash = { 'local_infile' => true }
        return Mysql2::Client.new(Storage[host: :db13, db: :usa_raw].merge(hash))
        # return Mysql2::Client.new(Storage[host: :db09, db: :astorchak_test])
      rescue StandardError => e
        logger.debug e
        logger.debug e.backtrace
      end

      sleep DB_RECONNECT_SLEEP
    end

    raise 'Unable create client database connection'
  end
end
