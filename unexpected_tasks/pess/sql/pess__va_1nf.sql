#= initiate variables, add new dataSET in DB ==========================================================================#

SET @created_by = 'Oleksii Kuts';

SET @data_source_url = 'http://data.richmond.com/salaries/2018/state';

INSERT INTO pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url, created_by)
VALUES ('db01.usa_raw', 'virginia_public_%', 'Virginia Public Employee Salaries', 'Scrape', @data_source_url, @created_by);

SET @dataset_id = (SELECT id
                     FROM pess_raw_datasets
                    WHERE data_source_name = 'Virginia Public Employee Salaries');

INSERT INTO pess_raw_dataset_tables(table_name, raw_dataset_id, created_by)
VALUES ('virginia_public_employee_salary', @dataset_id, @created_by);

SET @dataset_id = (SELECT id
                     FROM pess_raw_dataset_tables
                    WHERE table_name = 'virginia_public_employee_salary');

-- INSERT INTO pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
-- VALUES ('YTD Gross Pay', 0, 'YTD Gross Pay', @created_by)
--     ON DUPLICATE KEY
-- UPDATE raw_compensation_type = raw_compensation_type;

#= create =============================================================================================================#

-- CREATE TABLE tmp_va_1nf LIKE usa_raw.virginia_public_employee_salary;

-- ALTER TABLE tmp_va_1nf
--       DROP COLUMN agency_id,
--       DROP COLUMN checksum,
--       DROP COLUMN scrape_dev_name,
--       DROP COLUMN updated_at,
--       DROP COLUMN exported_at,
--       DROP COLUMN scrape_frequency,
--       DROP COLUMN name_url;
--
-- | id               | bigint(20)   | NO   | PRI | NULL                | auto_increment              |
-- | agency_id        | int(11)      | NO   | MUL | NULL                |                             |
-- | first_name       | varchar(255) | YES  |     | NULL                |                             |
-- | last_name        | varchar(255) | YES  |     | NULL                |                             |
-- | middle_name      | varchar(255) | YES  |     | NULL                |                             |
-- | agency           | varchar(255) | YES  |     | NULL                |                             |
-- | job              | varchar(255) | YES  |     | NULL                |                             |
-- | year             | mediumint(9) | NO   |     | NULL                |                             |
-- | annual_salary    | int(11)      | YES  |     | NULL                |                             |
-- | checksum         | varchar(128) | NO   |     | NULL                |                             |
-- | scrape_dev_name  | varchar(32)  | NO   |     | vsviridov           |                             |
-- | data_source_url  | varchar(255) | NO   |     | NULL                |                             |
-- | updated_at       | timestamp    | NO   | MUL | CURRENT_TIMESTAMP   | on update CURRENT_TIMESTAMP |
-- | exported_at      | datetime     | NO   | MUL | 0000-00-00 00:00:00 |                             |
-- | scrape_frequency | varchar(32)  | NO   |     | yearly              |                             |
-- | full_name        | varchar(255) | YES  |     | NULL                |                             |
-- | name_url         | varchar(255) | YES  |     | NULL                |                             |

#= insert =============================================================================================================#
INSERT INTO tmp_va_1nf (full_name, last_name, first_name, middle_name, agency, job, year, annual_salary, data_source_url, md5_employee, md5_agency)
SELECT s1.full_name, s1.last_name, s1.first_name, e1.middle_name, s1.agency, s1.job_title, s1.year, s1.annual_salary, IFNULL(s1.name_url, @data_source_url),
       MD5(CONCAT_WS('+', s1.full_name, s1.agency, s1.job_title, @data_source_url)),
       MD5(CONCAT_WS('+', s1.agency, @data_source_url))
  FROM usa_raw.virginia_public_employee_salary e1
       INNER JOIN usa_raw.virginia_public_employee_salary__spreadsheet s1
       ON e1.id = s1.id
 WHERE s1.agency NOT REGEXP '(educ|univers|instit|coll|academ|school|^$)';
       -- AND emp_name NOT REGEXP '(^PROTECTED|^CLIENT)';

-- ALTER TABLE tmp_va_1nf
--   ADD COLUMN md5_employee CHAR(32) NULL AFTER id, ADD INDEX(md5_employee),
--   ADD COLUMN employee_id BIGINT(20) NULL AFTER md5_employee, ADD INDEX(employee_id),
--   ADD COLUMN job_title_id BIGINT(20) NULL AFTER job,
--   ADD COLUMN md5_agency CHAR(32) NULL AFTER job_title_id, ADD INDEX(md5_agency),
--   ADD COLUMN agency_id BIGINT(20) NULL AFTER md5_agency, ADD INDEX(agency_id),
--   ADD COLUMN md5_ewy CHAR(32) NULL AFTER agency_id, ADD INDEX(md5_ewy),
--   ADD COLUMN ewy_id BIGINT(20) NULL AFTER md5_ewy, ADD INDEX(ewy_id),
--   ADD COLUMN md5_comp_annual_salary CHAR(32) NULL AFTER ewy_id, ADD INDEX(md5_comp_annual_salary),
--   ADD COLUMN annual_salary_id BIGINT(20) NULL AFTER md5_comp_annual_salary,
--   ADD COLUMN md5_address CHAR(32) NULL AFTER annual_salary_id, ADD INDEX(md5_address),
--   ADD COLUMN address_id BIGINT(20) NULL AFTER md5_address, ADD INDEX(address_id),
--   ADD COLUMN agency_location_id BIGINT(20) NULL AFTER address_id, ADD INDEX(agency_location_id),
--   ADD COLUMN etl_id BIGINT(20) NULL AFTER agency_location_id;

#= employees ==========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging with data from the temporary table
--    + Deal with employees that has no cleaned names
INSERT IGNORE INTO pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name, data_source_url, state, dataset_id, created_by)
SELECT t2.md5_employee, (f2.full_name_clean is not null), IFNULL(f2.full_name_clean, t2.full_name), t2.first_name, NULLIF(t2.middle_name, ''), t2.last_name,
       t2.data_source_url, 'VA', @dataset_id, @created_by
  FROM (SELECT t1.last_name, t1.first_name, t1.middle_name, t1.full_name, t1.md5_employee, t1.data_source_url
          FROM tmp_va_1nf t1
         GROUP BY t1.md5_employee) t2
       LEFT JOIN usa_raw.virginia_public_employee_salary__names_clean f2
       ON t2.full_name = f2.full_name; -- 19_269 of 50_537 unique

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_va_1nf t1
       LEFT JOIN pess_employees e1
       ON t1.md5_employee = e1.raw_employee_md5_hash
   SET t1.employee_id = e1.id;

#= job_titles =========================================================================================================#
INSERT IGNORE INTO pess_job_titles (raw_job_title, cleaned, job_title, created_by)
SELECT j1.job                     AS raw_job_title,
       (j1.job_clean IS NOT NULL) AS cleaned,
       j1.job_clean               AS job_title,
       @created_by                AS created_by
  FROM usa_raw.virginia_public_employee_salary__job_title_clean j1
       JOIN (SELECT DISTINCT job FROM tmp_va_1nf) t1
       ON j1.job = t1.job;

UPDATE tmp_va_1nf t1
       LEFT JOIN pess_job_titles j1
       ON t1.job = j1.raw_job_title
   SET t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging
INSERT IGNORE INTO pess_agencies (raw_agency_md5_hash, raw_agency_name, data_source_url, dataset_id, created_by)
SELECT DISTINCT t1.md5_agency, t1.agency, @data_source_url, @dataset_id, @created_by
  FROM tmp_va_1nf t1
 WHERE t1.md5_agency IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_va_1nf t1
       LEFT JOIN pess_agencies a1
       ON t1.md5_agency = a1.raw_agency_md5_hash
   SET t1.agency_id = a1.id;

-- 4. Update staging with data from the temporary table by hashes
--    + Deal with agencies that has no cleaned names
UPDATE pess_agencies t1
       LEFT JOIN usa_raw.virginia_public_employee_salary__spreadsheet s1
       ON t1.raw_agency_name = s1.agency
   SET t1.cleaned     = 0,
       t1.pl_org_id   = NULL,
       t1.agency_name = t1.raw_agency_name,
       t1.limpar_uuid = s1.limpar_org_id
 WHERE t1.dataset_id = @dataset_id;

#= employee_work_years ================================================================================================#
-- 1. Calculating the hash in the temporary table
UPDATE tmp_va_1nf
   SET md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, year, '', 'Salary', '',
                            ifnull(job_title_id, ''), @dataset_id, id, @data_source_url))
 WHERE annual_salary IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO pess_employee_work_years (md5_hash, employee_id, agency_id, year, job_title_id, raw_dataset_table_id_raw_id, raw_dataset_table_id, data_source_url, created_by, pay_type)
SELECT DISTINCT t1.md5_ewy, t1.employee_id, t1.agency_id, t1.year, t1.job_title_id, t1.id,
       @dataset_id, @data_source_url, @created_by, 'Salary'
  FROM tmp_va_1nf t1
 WHERE t1.md5_ewy IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_va_1nf t1
       JOIN pess_employee_work_years e1
       ON t1.md5_ewy = e1.md5_hash
   SET t1.ewy_id = e1.id;

#= compensations ======================================================================================================#
#=========================== Annual Salary ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Annual Salary');

-- 1. Calculating the hash in the temporary table
UPDATE tmp_va_1nf
   SET md5_comp_annual_salary = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, annual_salary, @dataset_id, @data_source_url))
 WHERE annual_salary IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp_annual_salary, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, 1, @dataset_id, @data_source_url, @created_by
  FROM tmp_va_1nf t1
 WHERE t1.md5_comp_annual_salary IS NOT NULL;


#= we DO NOT HAVE addresses ==========================================================================================================#
-- #= addresses ==========================================================================================================#
-- -- 1. Calculating the hash in the temporary table
-- UPDATE tmp_va_1nf t1
--        JOIN usa_raw.virginia_public_agency a1
--        ON t1.agency = a1.name
--    SET md5_address = MD5(CONCAT_WS('+', ifnull(a1.name, ''),  ifnull(@address, ''), ifnull(@city, ''),
--                      ifnull(@state, ''), ifnull(@zip, '')));
--
-- -- 2. Putting unique hashes into staging
-- INSERT INTO pess_addresses (raw_address_md5_hash, street_address, city, state, zip, created_by)
-- -- SELECT t2.md5_address, ua1.address, ua1.city, 'VA', ua1.zip, @created_by
-- SELECT DISTINCT t2.md5_address, NULL, NULL, 'VA', NULL, @created_by
--   FROM (SELECT DISTINCT t1.md5_address, t1.agency
--           FROM tmp_va_1nf t1) t2
--        JOIN usa_raw.virginia_public_agency ua1
--        ON t2.agency = ua1.name
--  WHERE t2.md5_address IS NOT NULL;
--
-- -- 3. Transfer the obtained IDs to the temporary table
-- UPDATE tmp_va_1nf t1
--        JOIN pess_addresses a1
--        ON t1.md5_address = a1.raw_address_md5_hash
--    SET t1.address_id = a1.id;
--
-- #= agency_locations ===================================================================================================#
-- INSERT INTO pess_agency_locations (address_id, agency_id, data_source_url, created_by)
-- SELECT DISTINCT t1.address_id, t1.agency_id, @data_source_url, @created_by
--   FROM tmp_va_1nf t1
--  WHERE t1.address_id IS NOT NULL;
--
-- UPDATE tmp_va_1nf t1
--        JOIN pess_agency_locations a1
--        ON t1.address_id = a1.address_id
--           AND t1.agency_id = a1.agency_id
--    SET t1.agency_location_id = a1.id;
--
-- #= employee_to_locations ==============================================================================================#
-- INSERT INTO pess_employees_to_locations (employee_id, agency_location_id, isolated_known_date, data_source_url, created_by)
-- SELECT DISTINCT t1.employee_id, t1.agency_location_id, t1.year, @data_source_url, @created_by
--   FROM tmp_va_1nf t1
--  WHERE t1.address_id IS NOT NULL;
--
-- UPDATE tmp_va_1nf t1
--        JOIN pess_employees_to_locations e1
--        ON t1.employee_id = e1.employee_id
--           AND t1.agency_location_id = e1.agency_location_id
--           AND t1.year = e1.isolated_known_date
--    SET t1.etl_id = e1.id;
--
-- #= employee_work_years ==============================================================================================#
-- UPDATE pess_employee_work_years e1
--        JOIN tmp_va_1nf t1
--        ON e1.id = t1.ewy_id
--    SET e1.employee_to_location_id = t1.etl_id,
--        e1.agency_location_id      = t1.agency_location_id
--  WHERE t1.etl_id IS NOT NULL;
-- #= ========================================= WORKING FROM HERE =================================================================#
