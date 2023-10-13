# frozen_string_literal: true

require_relative '../models/runs'
PREFIX = 'nppes_npi_registry__'
TABLES = %w(endpoints identifiers locations npidata other_names person_names taxonomies)

class  Keeper < Hamster::Harvester
  def initialize
    super
  end

  def store(csv_src, source)
    run_id_class = RunId.new(Runs)
    sql = get_sql(csv_src, run_id_class.run_id, source)
    queries = sql.split(';').map(&:strip)

    queries.each {|query| run_sql(query) unless query.empty?}

    run_id_class.finish
  end

  def run_sql(sql_text)
    logger.info "#{STARS}\n#{Time.now}#{STARS}\n#{sql_text}"
    Runs.connection.execute(sql_text)
  end

  def get_sql(csv_src, run_id, source)
    sql_text = ""
    sql_text = <<~SQL
    SET @run_id = #{run_id};
    SET @data_source_url = '#{source}';
    SET @created_by = 'Oleksii Kuts';

    CREATE TEMPORARY TABLE `nppes_npi_registry__endpoints_csv` LIKE `nppes_npi_registry__endpoints`;

    LOAD DATA LOCAL INFILE '#{csv_src[0]}'
        INTO TABLE `nppes_npi_registry__endpoints_csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@npi, @e_type, @e_type_description, @endpoint, @affiliation, @e_description, @aff_name, @use_code, @use_description, @other_use_description,
        @content_type, @content_description, @other_content_description, @addr_line1, @addr_line2, @city, @state, @country, @postal_code)
        SET run_id = @run_id,
            npi = @npi,
            endpoint_type = @e_type,
            endpoint_type_description = @e_type_description,
            endpoint = @endpoint,
            affiliation = @affiliation,
            endpoint_description =@e_description,
            affiliation_legal_buisiness_name = @aff_name,
            use_code = @use_code,
            use_description = @use_description,
            other_use_description = @other_use_description,
            content_type = @content_type,
            content_description = @content_description,
            other_content_description = @other_content_description,
            affiliation_address_line1 = @addr_line1,
            affiliation_address_line2 = @addr_line2,
            affiliation_address_city = @city,
            affiliation_address_state = @state,
            affiliation_address_country = @country,
            affiliation_address_postal_code = @postal_code,
            data_source_url = @data_source_url,
            touched_run_id = @run_id,
            md5_hash = MD5(CONCAT_WS('', @npi, @e_type, @e_type_description, @endpoint,
              @e_description, @aff_name, @use_code, @use_description,
              @other_use_description, @content_type, @content_description,
              @other_content_description, @addr_line1, @addr_line2, @city, @state,
              @country, @postal_code, @affiliation));

    ALTER TABLE `nppes_npi_registry__endpoints_csv` DROP COLUMN id;

    INSERT INTO `nppes_npi_registry__endpoints`
    SELECT null, t2.* FROM `nppes_npi_registry__endpoints_csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    DROP TEMPORARY TABLE `nppes_npi_registry__endpoints_csv`;

    LOAD DATA LOCAL INFILE '#{csv_src[1]}'
        INTO TABLE `nppes_npi_registry__npidata_csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES;

    CREATE TEMPORARY TABLE `nppes_npi_registry__other_names_csv` LIKE `nppes_npi_registry__other_names`;

    LOAD DATA LOCAL INFILE '#{csv_src[2]}'
        INTO TABLE `nppes_npi_registry__other_names_csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@npi, @other_name, @type_code)
        SET run_id = @run_id,
            npi = @npi,
            other_name = @other_name,
            name_type_code = @type_code,
            data_source_url = @data_source_url,
            touched_run_id = @run_id,
            md5_hash = MD5(CONCAT_WS('', @npi, @other_name, @type_code));

    ALTER TABLE `nppes_npi_registry__other_names_csv` DROP COLUMN id;

    INSERT INTO `nppes_npi_registry__other_names`
    SELECT null, t2.* FROM `nppes_npi_registry__other_names_csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    DROP TEMPORARY TABLE `nppes_npi_registry__other_names_csv`;

    CREATE TEMPORARY TABLE `nppes_npi_registry__locations_csv` LIKE `nppes_npi_registry__locations`;

    LOAD DATA LOCAL INFILE '#{csv_src[3]}'
        INTO TABLE `nppes_npi_registry__locations_csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@npi, @address_line1, @address_line2, @city_name, @state_name, @postal_code, @country_code, @phone_number, @phone_extension, @fax_number)
        SET run_id = @run_id,
            npi = @npi,
            address_line1 = @address_line1,
            address_line2 = @address_line2,
            city_name = @city_name,
            state_name = @state_name,
            postal_code = @postal_code,
            country_code = @country_code,
            phone_number = @phone_number,
            phone_extension = @phone_extension,
            fax_number = @fax_number,
            data_source_url = @data_source_url,
            touched_run_id = @run_id,
            md5_hash = MD5(CONCAT_WS('', @npi, @address_line1, @address_line2, @phone_number, @phone_extension, @fax_number, @city_name, @state_name, @postal_code, @country_code));

    ALTER TABLE `nppes_npi_registry__locations_csv` DROP COLUMN id;

    INSERT INTO `nppes_npi_registry__locations`
    SELECT null, t2.* FROM `nppes_npi_registry__locations_csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    DROP TEMPORARY TABLE `nppes_npi_registry__locations_csv`;

    INSERT into nppes_npi_registry__locations
    (SELECT
        null,
        @run_id,
        npi,
        @location_type := 'MAILING',
        @first_line := provider_first_line_business_mailing_address,
        @second_line := provider_second_line_business_mailing_address,
        @city := provider_business_mailing_address_city_name,
        @state := provider_business_mailing_address_state_name,
        @zip_code := provider_business_mailing_address_postal_code,
        @country_code := provider_business_mailing_address_country_code,
        @phone_number := provider_business_mailing_address_telephone_number,
        @phone_extension := '',
        @fax_number := provider_business_mailing_address_fax_number,
        @data_source_url,
        @created_by,
        current_timestamp(),
        current_timestamp(),
        @run_id as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', npi, @location_type, @first_line, @second_line, @city, @state, @zip_code,
          @country_code, @phone_number, @phone_extension, @fax_number))
    FROM usa_raw.nppes_npi_registry__npidata_csv
    WHERE provider_first_line_business_mailing_address != '')
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    INSERT into nppes_npi_registry__locations
    (SELECT
        null,
        @run_id,
        npi,
        @location_type := 'PRIMARY',
        @first_line := provider_first_line_business_practice_location_address,
        @second_line := provider_second_line_business_practice_location_address,
        @city := provider_business_practice_location_address_city_name,
        @state := provider_business_practice_location_address_state_name,
        @zip_code := provider_business_practice_location_address_postal_code,
        @country_code := provider_business_practice_location_address_country_code,
        @phone_number := provider_business_practice_location_address_telephone_number,
        @phone_extension := '',
        @fax_number := provider_business_practice_location_address_fax_number,
        @data_source_url,
        @created_by,
        current_timestamp(),
        current_timestamp(),
        @run_id as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', npi, @location_type, @first_line, @second_line, @city, @state, @zip_code,
          @country_code, @phone_number, @phone_extension, @fax_number))
    FROM usa_raw.nppes_npi_registry__npidata_csv
    WHERE provider_first_line_business_practice_location_address != '')
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    INSERT into nppes_npi_registry__person_names
    (SELECT
        null,
        @run_id as run_id,
        npi,
        @type := 'MAIN',
        @last := provider_last_name,
        @first := provider_first_name,
        @middle := provider_middle_name,
        @prefix := provider_name_prefix_text,
        @suffix := provider_name_suffix_text,
        @credential := provider_credential_text,
        @data_source_url,
        @created_by,
        current_timestamp(),
        current_timestamp(),
        @run_id as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', npi, @type, @last, @first, @middle, @prefix, @suffix, @credential))
    FROM usa_raw.nppes_npi_registry__npidata_csv
    WHERE provider_first_name != '')
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    INSERT into nppes_npi_registry__person_names
    (SELECT
        null,
        @run_id as run_id,
        npi,
        @type := 'OTHER',
        @last := provider_other_last_name,
        @first := provider_other_first_name,
        @middle := provider_other_middle_name,
        @prefix := provider_other_name_prefix_text,
        @suffix := provider_other_name_suffix_text,
        @credential := provider_other_credential_text,
        @data_source_url,
        @created_by,
        current_timestamp(),
        current_timestamp(),
        @run_id as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', npi, @type, @last, @first, @middle, @prefix, @suffix, @credential))
    FROM usa_raw.nppes_npi_registry__npidata_csv
    WHERE provider_other_last_name != '')
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    INSERT into nppes_npi_registry__person_names
    (SELECT
        null,
        @run_id as run_id,
        npi,
        @type := 'OFFICIAL',
        @last := authorized_official_last_name,
        @first := authorized_official_first_name,
        @middle := authorized_official_middle_name,
        @prefix := authorized_official_name_prefix_text,
        @suffix := authorized_official_name_suffix_text,
        @credential := authorized_official_credential_text,
        @data_source_url,
        @created_by,
        current_timestamp(),
        current_timestamp(),
        @run_id as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', npi, @type, @last, @first, @middle, @prefix, @suffix, @credential))
    FROM usa_raw.nppes_npi_registry__npidata_csv
    WHERE authorized_official_last_name != '')
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    INSERT into nppes_npi_registry__npidata
    (SELECT
        null,
        @run_id as run_id,
        npi,
        @p1 := entity_type_code,
        @p2 := replacement_npi,
        @p3 := `employer_identification_number_(ein)`,
        @p4 := provider_organization_name,
        @p5 := provider_other_organization_name,
        @p6 := provider_other_organization_name_type_code,
        @p7 := provider_other_last_name_type_code,
        @p8 := CASE
          WHEN provider_enumeration_date = '' THEN null
          ELSE STR_TO_DATE(`provider_enumeration_date`, '%m/%d/%Y')
        END,
        @p9 := CASE
          WHEN last_update_date = '' THEN null
          ELSE STR_TO_DATE(`last_update_date`, '%m/%d/%Y')
        END,
        @p10 := npi_deactivation_reason_code,
        @p11 := CASE
          WHEN npi_deactivation_date = '' THEN null
          ELSE STR_TO_DATE(`npi_deactivation_date`, '%m/%d/%Y')
        END,
        @p12 := CASE
          WHEN npi_reactivation_date = '' THEN null
          ELSE STR_TO_DATE(`npi_reactivation_date`, '%m/%d/%Y')
        END,
        @p13 := provider_gender_code,
        @p14 := authorized_official_title_or_position,
        @p15 := authorized_official_telephone_number,
        @p16 := is_sole_proprietor,
        @p17 := is_organization_subpart,
        @p18 := parent_organization_lbn,
        @p19 := parent_organization_tin,
        @p20 := CASE
          WHEN certification_date = '' THEN null
          ELSE STR_TO_DATE(`certification_date`, '%m/%d/%Y')
        END,
        @data_source_url,
        @created_by,
        current_timestamp(),
        current_timestamp(),
        @run_id as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', npi, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10,
          @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20))
    FROM usa_raw.nppes_npi_registry__npidata_csv)
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    SQL

    1.upto(15) do |n|
      sql_text += "
      insert into usa_raw.nppes_npi_registry__taxonomies
      select
          null,
          @run_id as run_id,
          npi,
          @taxonomy_code := healthcare_provider_taxonomy_code_#{n},
          @license_number := provider_license_number_#{n},
          @state_code := provider_license_number_state_code_#{n},
          @taxonomy_switch := healthcare_provider_primary_taxonomy_switch_#{n},
          @taxonomy_group := healthcare_provider_taxonomy_group_#{n},
          @order_number := #{n},
          @data_source_url,
          @created_by,
          current_timestamp(),
          current_timestamp(),
          @run_id as touched_run_id,
          0 as deleted,
          MD5(CONCAT_WS('', npi, @taxonomy_code, @license_number, @state_code, @taxonomy_switch, @taxonomy_group))
      FROM usa_raw.nppes_npi_registry__npidata_csv
      where healthcare_provider_taxonomy_code_#{n} != ''
      ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;"
    end

    1.upto(50) do |n|
      sql_text += "
      insert into usa_raw.nppes_npi_registry__identifiers
      select
          null,
          @run_id as run_id,
          npi,
          @identifier := other_provider_identifier_#{n},
          @type_code := other_provider_identifier_type_code_#{n},
          @state := other_provider_identifier_state_#{n},
          @issuer := other_provider_identifier_issuer_#{n} = replace(other_provider_identifier_issuer_#{n}, '\\\\', ''),
          @order_number := #{n},
          @data_source_url,
          @created_by,
          current_timestamp(),
          current_timestamp(),
          @run_id as touched_run_id,
          0 as deleted,
          MD5(CONCAT_WS('', npi, @identifier, @type_code, @state, @issuer))
      FROM usa_raw.nppes_npi_registry__npidata_csv
      where other_provider_identifier_#{n} != ''
      ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;"
    end

    sql_text += "
    TRUNCATE TABLE nppes_npi_registry__npidata_csv;"

    sql_text += update_run_id_sql()
  end

  def update_run_id_sql
    TABLES.map {|table| mark_deleted(table)}.join
  end

  def mark_deleted(table_name)
    <<~SQL
      UPDATE `#{PREFIX}#{table_name}` SET deleted = 1
      WHERE touched_run_id <> @run_id
      AND deleted = 0;
    SQL
  end
end
