insert ignore into common__arrestee_addresses (origin_table_id, origin_id, arrestee_id, full_address, street_address,
                                        unit_number, city, county, state, zip, lan, lon, data_source_url, created_by, deleted, md5_hash)
select 4, id, arrestee_id, full_address, street_address, unit_number, city,
       county, state, zip, lan, lon, data_source_url, 'Mikhail Golovanov', deleted, md5_hash from il_lake__arrestee_addresses where touched_run_id = 2;

insert ignore into common__arrestee_aliases (origin_table_id, origin_id, arrestee_id, full_name, first_name,
                                      middle_name, last_name, suffix, data_source_url, created_by,
                                      deleted, md5_hash)
select 4, id, arrestee_id, full_name, first_name, middle_name, last_name, suffix, data_source_url, 'Mikhail Golovanov',
       deleted, md5_hash from il_lake__arrestee_aliases where touched_run_id = 2;

insert ignore into common__arrestee_ids (origin_table_id, origin_id, arrestee_id, number, type, date_from, date_to, data_source_url, created_by, deleted, md5_hash)
SELECT 4, id, arrestee_id, number, type, date_from, date_to, data_source_url, 'Mikhail Golovanov', deleted, md5_hash from il_lake__arrestee_ids where touched_run_id = 2;

insert into common__arrestees (origin_table_id, origin_id, full_name, first_name, middle_name, last_name, suffix,
                               birthdate, age, age_as_of_date, race, sex, height, weight, data_source_url,
                               created_by,  deleted, md5_hash)
SELECT 4, id, full_name, first_name, middle_name, last_name, suffix, birthdate, age, age_as_of_date, race, sex, height,
       weight, data_source_url, 'Mikhail Golovanov', deleted, md5_hash from il_lake__arrestees where touched_run_id = 2;

insert ignore into common__arrests (origin_table_id, origin_id, arrestee_id, status, arrest_date, booking_date, booking_agency,
                             booking_agency_type, booking_agency_subtype, booking_number, data_source_url, created_by, deleted, md5_hash)
SELECT 4, id, arrestee_id, status, arrest_date, booking_date, booking_agency, booking_agency_type, booking_agency_subtype,
       booking_number, data_source_url, 'Mikhail Golovanov', deleted, md5_hash from il_lake__arrests where touched_run_id = 2;

insert ignore into common__bonds (origin_table_id, origin_id, arrest_id, charge_id, bond_category, bond_number, bond_type,
                           bond_amount, paid, made_bond_release_date, made_bond_release_time, data_source_url, created_by, deleted, md5_hash)
SELECT 4, id, arrest_id, charge_id, bond_category, bond_number, bond_type, bond_amount, paid, made_bond_release_date,
       made_bond_release_time, data_source_url, 'Mikhail Golovanov', deleted, md5_hash from il_lake__bonds where touched_run_id = 2;

insert ignore into common__charges (origin_table_id, origin_id, arrest_id, number, disposition, disposition_date, description,
                             offense_date, offense_time, attempt_or_commit, docker_number, data_source_url, created_by, deleted, md5_hash)
SELECT 4, id, arrest_id, number, disposition, disposition_date, description, offense_date, offense_time, attempt_or_commit,
       docket_number, data_source_url, 'Mikhail Golovanov', deleted, md5_hash from il_lake__charges where touched_run_id = 2;

insert ignore into common__mugshots (origin_table_id, origin_id, arrestee_id, aws_link, original_link, notes,
                                    created_by, deleted, md5_hash)
SELECT 4, id, arrestee_id, aws_link, original_link, notes,
       'Mikhail Golovanov', deleted, md5_hash from il_lake__mugshots where touched_run_id = 2;



SELECT * FROM crime_perps__step_1.registry;
SELECT SUB(TABLE_NAME) FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'crime_perps__step_1' AND TABLE_NAME LIKE "il_lake__%";
SELECT SUBSTR(TABLE_NAME, 9) FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'crime_perps__step_1' AND TABLE_NAME LIKE "common__%" AND TABLE_NAME <> "common__runs";

SELECT t2.COLUMN_NAME FROM ( SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='crime_perps__step_1' AND TABLE_NAME='il_kane__arrests' ) AS t2
    CROSS JOIN (SELECT  TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='crime_perps__step_1' AND TABLE_NAME='common__arrests' ) AS t1 ON t2.COLUMN_NAME = t1.COLUMN_NAME WHERE t2.COLUMN_NAME NOT IN ('run_id', 'created_by', 'created_at', 'updated_at', 'id');

SELECT  count(*) FROM common__arrestee_addresses;
SELECT  count(*) FROM common__arrestee_aliases;
SELECT  count(*) FROM common__arrestees;
SELECT  count(*) FROM common__arrests;
SELECT  count(*) FROM common__bonds;
SELECT  count(*) FROM common__charges;
SELECT  count(*) FROM common__court_hearings;
SELECT  count(*) FROM common__holding_facilities;
SELECT  count(*) FROM common__mugshots;

UPDATE common__arrestee_addresses SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__arrestee_aliases SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__arrestee_ids SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__bonds SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__charges SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__court_hearings SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__holding_facilities SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;
UPDATE common__mugshots SET run_id = 1, touched_run_id = 1 WHERE origin_table_id = 4;


SELECT count(*) FROM common__arrestees WHERE origin_table_id = 1;
SELECT count(*) FROM il_kendall__arrestees;

UPDATE common__arrestees, (SELECT il_kendall__arrestees.* FROM il_kendall__arrestees LEFT JOIN common__arrestees ON origin_table_id = 1 AND origin_id = id WHERE origin_id is not null ) AS t1 SET ;
SELECT il_kendall__arrestees.* FROM il_kendall__arrestees LEFT JOIN common__arrestees ON origin_table_id = 1 AND origin_id = id WHERE origin_id is null;