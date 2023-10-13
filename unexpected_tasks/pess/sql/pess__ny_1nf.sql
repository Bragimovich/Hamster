#= initiate variables, add new dataSET in DB ==========================================================================#

SET @created_by = 'Oleksii Kuts';

SET @data_source_url = 'https://www.seethroughny.net/payrolls';

SET @dataset_already_inserted = (SELECT id
                                   FROM pess_raw_datasets
                                  WHERE data_source_name = 'State of New York Public Salary');

INSERT INTO pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url, created_by)
SELECT 'db01.state_salaries__raw', 'ny_public_salaries%', 'State of New York Public Salary', 'Scrape', @data_source_url, @created_by
 WHERE @dataset_already_inserted IS NULL;

SET @dataset_id = (SELECT id
                     FROM pess_raw_datasets
                    WHERE data_source_name = 'State of New York Public Salary');

SET @dataset_already_inserted = (SELECT id
                                   FROM pess_raw_dataset_tables
                                  WHERE table_name = 'ny_public_salaries');

INSERT INTO pess_raw_dataset_tables(table_name, raw_dataset_id, created_by)
SELECT 'ny_public_salaries', @dataset_id, @created_by
 WHERE @dataset_already_inserted IS NULL;

SET @dataset_id = (SELECT id
                     FROM pess_raw_dataset_tables
                    WHERE table_name = 'ny_public_salaries');

#= create =============================================================================================================#

-- CREATE TABLE tmp_ny_1nf LIKE state_salaries__raw.ny_public_salaries;

-- ALTER TABLE tmp_ny_1nf
--       DROP COLUMN subagency,
--       DROP COLUMN rate_of_pay,
--       DROP COLUMN pay_year,
--       DROP COLUMN pay_basis,
--       DROP COLUMN branch,
--       DROP COLUMN created_by,
--       DROP COLUMN created_at,
--       DROP COLUMN updated_at,
--       DROP COLUMN run_id,
--       DROP COLUMN touched_run_id,
--       DROP COLUMN deleted,
--       DROP COLUMN md5_hash;
--
-- | id              | bigint(20)   | NO   | PRI | NULL              | auto_increment              |
-- | name            | varchar(255) | YES  |     | NULL              |                             |
-- | employer        | varchar(255) | YES  |     | NULL              |                             |
-- | total_pay       | varchar(255) | YES  |     | NULL              |                             |
-- | subagency       | varchar(255) | YES  |     | NULL              |                             |
-- | title           | varchar(255) | YES  |     | NULL              |                             |
-- | rate_of_pay     | varchar(255) | YES  |     | NULL              |                             |
-- | pay_year        | varchar(255) | YES  |     | NULL              |                             |
-- | pay_basis       | varchar(255) | YES  |     | NULL              |                             |
-- | branch          | varchar(255) | YES  |     | NULL              |                             |
-- | year            | varchar(255) | YES  |     | NULL              |                             |
-- | data_source_url | varchar(100) | YES  |     | NULL              |                             |
-- | created_by      | varchar(255) | YES  |     | Umar              |                             |
-- | created_at      | datetime     | YES  |     | CURRENT_TIMESTAMP |                             |
-- | updated_at      | datetime     | NO   |     | CURRENT_TIMESTAMP | on update CURRENT_TIMESTAMP |
-- | run_id          | bigint(20)   | YES  | MUL | NULL              |                             |
-- | touched_run_id  | bigint(20)   | YES  | MUL | NULL              |                             |
-- | deleted         | tinyint(1)   | YES  | MUL | 0                 |                             |
-- | md5_hash        | varchar(255) | YES  | UNI | NULL              |                             |

-- ALTER TABLE tmp_ny_1nf
--   ADD COLUMN md5_employee CHAR(32) NULL AFTER id, ADD INDEX(md5_employee),
--   ADD COLUMN employee_id BIGINT(20) NULL AFTER md5_employee, ADD INDEX(employee_id),
--   ADD COLUMN job_title_id BIGINT(20) NULL AFTER employee_id,
--   ADD COLUMN md5_agency CHAR(32) NULL AFTER job_title_id, ADD INDEX(md5_agency),
--   ADD COLUMN agency_id BIGINT(20) NULL AFTER md5_agency, ADD INDEX(agency_id),
--   ADD COLUMN md5_ewy CHAR(32) NULL AFTER agency_id, ADD INDEX(md5_ewy),
--   ADD COLUMN ewy_id BIGINT(20) NULL AFTER md5_ewy, ADD INDEX(ewy_id),
--   ADD COLUMN md5_comp_annual_salary CHAR(32) NULL AFTER ewy_id, ADD INDEX(md5_comp_annual_salary),
--   ADD COLUMN annual_salary_id BIGINT(20) NULL AFTER md5_comp_annual_salary;

#= insert =============================================================================================================#
SELECT @created_by, @data_source_url, @dataset_id;

INSERT INTO tmp_ny_1nf (name, employer, title, year, total_pay, data_source_url, md5_employee, md5_agency)
SELECT s1.name, s1.employer, s1.title, s1.year, s1.total_pay, @data_source_url,
       MD5(CONCAT_WS('+', s1.name, s1.employer, s1.title, @data_source_url)),
       MD5(CONCAT_WS('+', s1.employer, @data_source_url))
  FROM state_salaries__raw.ny_public_salaries s1
 WHERE s1.employer NOT REGEXP '(educ|univers|instit|coll|academ|school|^$)'
       AND s1.name NOT REGEXP 'xxx|redacted|^ndr$'; -- 13_623_596

#= employees ==========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging with data from the temporary table
--    + Deal with employees that has no cleaned names
INSERT IGNORE INTO pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name, suffix, data_source_url, state, dataset_id, created_by)
SELECT t2.md5_employee, (f2.name_clean is not null), IFNULL(f2.name_clean, t2.name), f2.first_name, NULLIF(f2.middle_name, ''), f2.last_name, f2.suffix,
       @data_source_url, 'NY', @dataset_id, @created_by
  FROM (SELECT t1.name, t1.md5_employee
          FROM tmp_ny_1nf t1
         GROUP BY t1.md5_employee) t2
       LEFT JOIN state_salaries__raw.ny_public_salaries__names_clean f2
       ON t2.name = f2.name; -- 4_379_872 of 3_636_518 unique (2_521_859 distinct full_name)

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_ny_1nf t1
       LEFT JOIN pess_employees e1
       ON t1.md5_employee = e1.raw_employee_md5_hash
   SET t1.employee_id = e1.id;

#= job_titles =========================================================================================================#
INSERT IGNORE INTO pess_job_titles (raw_job_title, cleaned, job_title, created_by)
SELECT j1.title                     AS raw_job_title,
       (j1.title_clean IS NOT NULL) AS cleaned,
       j1.title_clean               AS job_title,
       @created_by                  AS created_by
  FROM state_salaries__raw.ny_public_salaries__title_clean j1
       JOIN (SELECT DISTINCT title FROM tmp_ny_1nf) t1
       ON j1.title = t1.title;

UPDATE tmp_ny_1nf t1
       LEFT JOIN pess_job_titles j1
       ON t1.title = j1.raw_job_title
   SET t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging
INSERT IGNORE INTO pess_agencies (raw_agency_md5_hash, raw_agency_name, data_source_url, dataset_id, created_by)
SELECT DISTINCT t1.md5_agency, t1.employer, @data_source_url, @dataset_id, @created_by
  FROM tmp_ny_1nf t1
 WHERE t1.md5_agency IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_ny_1nf t1
       LEFT JOIN pess_agencies a1
       ON t1.md5_agency = a1.raw_agency_md5_hash
   SET t1.agency_id = a1.id;

-- 4. Update staging with data from the temporary table by hashes
--    + Deal with agencies that has no cleaned names
UPDATE pess_agencies t1
       LEFT JOIN state_salaries__raw.ny_public_salaries__employer_clean s1
       ON t1.raw_agency_name = s1.employer
   SET t1.cleaned     = (s1.employer_clean IS NOT NULL),
       t1.pl_org_id   = NULL,
       t1.agency_name = IFNULL(s1.employer_clean, t1.raw_agency_name),
       t1.limpar_uuid = NULL
 WHERE t1.dataset_id = @dataset_id;

#= employee_work_years ================================================================================================#
-- 1. Calculating the hash in the temporary table
UPDATE tmp_ny_1nf
   SET md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, year, '', 'Salary', '',
                            ifnull(job_title_id, ''), @dataset_id, id, @data_source_url))
 WHERE total_pay IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO pess_employee_work_years (md5_hash, employee_id, agency_id, year, job_title_id, raw_dataset_table_id_raw_id, raw_dataset_table_id, data_source_url, created_by, pay_type)
SELECT DISTINCT t1.md5_ewy, t1.employee_id, t1.agency_id, t1.year, t1.job_title_id, t1.id,
       @dataset_id, @data_source_url, @created_by, 'Salary'
  FROM tmp_ny_1nf t1
 WHERE t1.md5_ewy IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_ny_1nf t1
       JOIN pess_employee_work_years e1
       ON t1.md5_ewy = e1.md5_hash
   SET t1.ewy_id = e1.id;

#= compensations ======================================================================================================#
#=========================== Toal Pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Total Pay');

-- 1. Calculating the hash in the temporary table
UPDATE tmp_ny_1nf
   SET md5_comp_annual_salary = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, total_pay, @dataset_id, @data_source_url))
 WHERE total_pay IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp_annual_salary, t1.ewy_id, @curr_comp_type_id, t1.total_pay, TRUE, @dataset_id, @data_source_url, @created_by
  FROM tmp_ny_1nf t1
 WHERE t1.md5_comp_annual_salary IS NOT NULL;


#= ========================================= WORKING FROM HERE =================================================================#
#= we DO NOT HAVE addresses ==========================================================================================================#
-- #= addresses ==========================================================================================================#
-- -- 1. Calculating the hash in the temporary table
-- UPDATE tmp_ny_1nf t1
--        JOIN state_salaries__raw.virginia_public_agency a1
--        ON t1.agency = a1.name
--    SET md5_address = MD5(CONCAT_WS('+', ifnull(a1.name, ''),  ifnull(@address, ''), ifnull(@city, ''),
--                      ifnull(@state, ''), ifnull(@zip, '')));
--
-- -- 2. Putting unique hashes into staging
-- INSERT INTO pess_addresses (raw_address_md5_hash, street_address, city, state, zip, created_by)
-- -- SELECT t2.md5_address, ua1.address, ua1.city, 'VA', ua1.zip, @created_by
-- SELECT DISTINCT t2.md5_address, NULL, NULL, 'VA', NULL, @created_by
--   FROM (SELECT DISTINCT t1.md5_address, t1.agency
--           FROM tmp_ny_1nf t1) t2
--        JOIN state_salaries__raw.virginia_public_agency ua1
--        ON t2.agency = ua1.name
--  WHERE t2.md5_address IS NOT NULL;
--
-- -- 3. Transfer the obtained IDs to the temporary table
-- UPDATE tmp_ny_1nf t1
--        JOIN pess_addresses a1
--        ON t1.md5_address = a1.raw_address_md5_hash
--    SET t1.address_id = a1.id;
--
-- #= agency_locations ===================================================================================================#
-- INSERT INTO pess_agency_locations (address_id, agency_id, data_source_url, created_by)
-- SELECT DISTINCT t1.address_id, t1.agency_id, @data_source_url, @created_by
--   FROM tmp_ny_1nf t1
--  WHERE t1.address_id IS NOT NULL;
--
-- UPDATE tmp_ny_1nf t1
--        JOIN pess_agency_locations a1
--        ON t1.address_id = a1.address_id
--           AND t1.agency_id = a1.agency_id
--    SET t1.agency_location_id = a1.id;
--
-- #= employee_to_locations ==============================================================================================#
-- INSERT INTO pess_employees_to_locations (employee_id, agency_location_id, isolated_known_date, data_source_url, created_by)
-- SELECT DISTINCT t1.employee_id, t1.agency_location_id, t1.year, @data_source_url, @created_by
--   FROM tmp_ny_1nf t1
--  WHERE t1.address_id IS NOT NULL;
--
-- UPDATE tmp_ny_1nf t1
--        JOIN pess_employees_to_locations e1
--        ON t1.employee_id = e1.employee_id
--           AND t1.agency_location_id = e1.agency_location_id
--           AND t1.year = e1.isolated_known_date
--    SET t1.etl_id = e1.id;
--
-- #= employee_work_years ==============================================================================================#
-- UPDATE pess_employee_work_years e1
--        JOIN tmp_ny_1nf t1
--        ON e1.id = t1.ewy_id
--    SET e1.employee_to_location_id = t1.etl_id,
--        e1.agency_location_id      = t1.agency_location_id
--  WHERE t1.etl_id IS NOT NULL;
