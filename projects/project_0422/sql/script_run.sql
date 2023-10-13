SET @data_source_url = 'https://download.cms.gov/nppes/NPPES_Data_Dissemination_May_2022.zip';
SET @created_by = 'Oleksii Kuts';

LOAD DATA LOCAL INFILE '/home/developer/HarvestStorehouse/project_0422/store/othername_pfile_20050523-20220508.csv'
    INTO TABLE `nppes_npi_registry__other_names`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@npi, @other_name, @type_code)
    SET run_id = 1,
        npi = @npi,
        other_name = @other_name,
        name_type_code = @type_code,
        data_source_url = @data_source_url,
        touched_run_id = 1,
        md5_hash = MD5(CONCAT_WS('', @npi, @other_name, @type_code));

LOAD DATA LOCAL INFILE '/home/developer/HarvestStorehouse/project_0422/store/pl_pfile_20050523-20220508.csv'
    INTO TABLE `nppes_npi_registry__locations`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@npi, @address_line1, @address_line2, @city_name, @state_name, @postal_code, @country_code, @phone_number, @phone_extension, @fax_number)
    SET run_id = 1,
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
        touched_run_id = 1,
        md5_hash = MD5(CONCAT_WS('', @npi, @address_line1, @address_line2, @phone_number, @phone_extension, @fax_number, @city_name, @state_name, @postal_code, @country_code));


LOAD DATA LOCAL INFILE '/home/developer/HarvestStorehouse/project_0422/store/endpoint_pfile_20050523-20220508.csv'
    INTO TABLE `nppes_npi_registry__endpoints`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@npi, @e_type, @e_type_description, @endpoint, @affiliation, @e_description, @aff_name, @use_code, @use_description, @other_use_description,
    @content_type, @content_description, @other_content_description, @addr_line1, @addr_line2, @city, @state, @country, @postal_code)
    SET run_id = 1,
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
        touched_run_id = 1,
        md5_hash = MD5(CONCAT_WS('', @npi, @e_type, @e_type_description, @endpoint,
          @e_description, @aff_name, @use_code, @use_description,
          @other_use_description, @content_type, @content_description,
          @other_content_description, @addr_line1, @addr_line2, @city, @state,
          @country, @postal_code, @affiliation));

LOAD DATA LOCAL INFILE '/home/developer/HarvestStorehouse/project_0422/store/npidata_pfile_20220509-20220515.csv'
    INTO TABLE `nppes_npi_registry__npidata_csv`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

#=================================================================

# сделать цикл 15 раз
INSERT into nppes_npi_registry__taxonomies
(SELECT
    1 AS run_id,
  	npi,
  	healthcare_provider_taxonomy_code_1 AS taxonomy_code,
    provider_license_number_1 AS license_number,
    provider_license_number_state_code_1 AS state_code,
    healthcare_provider_primary_taxonomy_switch_1 AS taxonomy_switch,
    healthcare_provider_taxonomy_group_1 AS taxonomy_group,
    @data_source_url AS data_source_url

FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE healthcare_provider_taxonomy_code_1 != '');


# сделать цикл 50 раз
INSERT into nppes_npi_registry__identifiers
(SELECT
  	npi,
  	other_provider_identifier_1 AS identifier,
    other_provider_identifier_type_code_1 AS type_code,
    other_provider_identifier_state_1 AS state,
    other_provider_identifier_issuer_1 AS issuer
FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE other_provider_identifier_1 != '');

INSERT into nppes_npi_registry__locations
(SELECT
  	npi,
    location_type = 'MAILING',
    provider_first_line_business_mailing_address,
    provider_second_line_business_mailing_address,
    provider_business_mailing_address_city_name,
    provider_business_mailing_address_state_name,
    provider_business_mailing_address_postal_code,
    provider_business_mailing_address_country_code,
    provider_business_mailing_address_telephone_number,
    '',
    provider_business_mailing_address_fax_number
FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE provider_first_line_business_mailing_address != '');

INSERT into nppes_npi_registry__locations
(SELECT
  	npi,
    location_type = 'PRIMARY',
    provider_first_line_business_practice_location_address,
    provider_second_line_business_practice_location_address,
    provider_business_practice_location_address_city_name,
    provider_business_practice_location_address_state_name,
    provider_business_practice_location_address_postal_code,
    provider_business_practice_location_address_country_code,
    provider_business_practice_location_address_telephone_number,
    '',
    provider_business_practice_location_address_fax_number
FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE provider_first_line_business_practice_location_address != '');

INSERT into nppes_npi_registry__person_names
(SELECT
  	npi,
    name_type = 'MAIN',
    provider_last_name,
    provider_first_name,
    provider_middle_name,
    provider_name_prefix_text,
    provider_name_suffix_text,
    provider_credential_text
FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE provider_first_name != '');

INSERT into nppes_npi_registry__person_names
(SELECT
  	npi,
    name_type = 'OTHER',
    provider_other_last_name,
    provider_other_first_name,
    provider_other_middle_name,
    provider_other_name_prefix_text,
    provider_other_name_suffix_text,
    provider_other_credential_text
FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE provider_other_last_name != '');

INSERT into nppes_npi_registry__person_names
(SELECT
  	npi,
    name_type = 'OFFICIAL',
    authorized_official_last_name,
    authorized_official_first_name,
    authorized_official_middle_name,
    authorized_official_name_prefix_text,
    authorized_official_name_suffix_text,
    authorized_official_credential_text
FROM usa_raw.nppes_npi_registry__npidata_csv
WHERE authorized_official_last_name != '');

INSERT into nppes_npi_registry__npidata
(SELECT
  	npi,
    entity_type_code,
    replacement_npi,
    employer_identification_number_(ein),
    provider_organization_name,
    provider_other_organization_name,
    provider_other_organization_name_type_code,
    provider_other_last_name_type_code,
    provider_enumeration_date,
    last_update_date,
    npi_deactivation_reason_code,
    npi_deactivation_date,
    npi_reactivation_date,
    provider_gender_code,
    authorized_official_title_or_position,
    authorized_official_telephone_number,
    is_sole_proprietor,
    is_organization_subpart,
    parent_organization_lbn,
    parent_organization_tin,
    certification_date
FROM usa_raw.nppes_npi_registry__npidata_csv;
