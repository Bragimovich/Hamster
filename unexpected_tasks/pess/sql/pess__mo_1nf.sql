#= initiate variables, add new dataSET in DB ==========================================================================#

SET @created_by = 'Oleksii Kuts';

SET @data_source_url = 'https://mapyourtaxes.mo.gov/MAP/Download/Default.aspx';

INSERT INTO pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url, created_by)
VALUES ('db01.usa_raw', 'MO_public_employee_salary%', 'Missouri Public Employee Salary', 'Scrape', @data_source_url, @created_by);

SET @dataset_id = (SELECT id
                     FROM pess_raw_datasets
                    WHERE data_source_name = 'Missouri Public Employee Salary');

INSERT INTO pess_raw_dataset_tables(table_name, raw_dataset_id, created_by)
VALUES ('MO_public_employee_salary', @dataset_id, @created_by);

SET @dataset_id = (SELECT id
                     FROM pess_raw_dataset_tables
                    WHERE table_name = 'MO_public_employee_salary');

-- INSERT INTO pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
-- VALUES ('YTD Gross Pay', 0, 'YTD Gross Pay', @created_by)
--     ON DUPLICATE KEY
-- UPDATE raw_compensation_type = raw_compensation_type;

#= create =============================================================================================================#

-- CREATE TABLE tmp_mo_1nf LIKE usa_raw.MO_public_employee_salary;

INSERT INTO tmp_mo_1nf (emp_name, last_name, first_name, middle_name, full_name, year, agency_name, position_title, gross_pay, data_source_url, md5_employee, md5_agency)
SELECT emp_name, last_name, first_name, middle_name, full_name, year, agency_name, position_title, gross_pay, @data_source_url,
       MD5(CONCAT_WS('+', first_name, IFNULL(middle_name, ''), last_name, @data_source_url)),
       MD5(CONCAT_WS('+', agency_name, @data_source_url))
  FROM usa_raw.MO_public_employee_salary
 WHERE agency_name NOT REGEXP '(educ|^$)'
       AND emp_name NOT REGEXP '(^PROTECTED|^CLIENT)';

-- ALTER TABLE tmp_mo_1nf
--       DROP COLUMN data_file_name,
--       DROP COLUMN created_at,
--       DROP COLUMN updated_at,
--       DROP COLUMN scrape_dev_name,
--       DROP COLUMN scrape_frequency,
--       DROP COLUMN last_scrape_date,
--       DROP COLUMN next_scrape_date,
--       DROP COLUMN expected_scrape_frequency,
--       DROP COLUMN dataset_name_prefix,
--       DROP COLUMN scrape_status,
--       DROP COLUMN pl_gather_task_id;

    -- | id                        | bigint       | NO   | PRI | NULL                | auto_increment    |
    -- | data_file_name            | varchar(255) | YES  |     | NULL                |                   |
    -- | emp_name                  | varchar(255) | YES  |     | NULL                |                   |
    -- | last_name                 | varchar(255) | YES  |     | NULL                |                   |
    -- | first_name                | varchar(255) | YES  |     | NULL                |                   |
    -- | middle_name               | varchar(255) | YES  |     | NULL                |                   |
    -- | full_name                 | varchar(255) | YES  |     | NULL                |                   |
    -- | year                      | varchar(255) | YES  | MUL | NULL                |                   |
    -- | agency_name               | varchar(255) | YES  |     | NULL                |                   |
    -- | position_title            | varchar(255) | YES  |     | NULL                |                   |
    -- | gross_pay                 | double       | YES  |     | NULL                |                   |
    -- | created_at                | timestamp    | NO   |     | CURRENT_TIMESTAMP   | DEFAULT_GENERATED |
    -- | updated_at                | timestamp    | NO   |     | 0000-00-00 00:00:00 |                   |
    -- | data_source_url           | varchar(255) | YES  |     | NULL                |                   |
    -- | scrape_dev_name           | varchar(255) | YES  |     | NULL                |                   |
    -- | scrape_frequency          | varchar(255) | YES  |     | NULL                |                   |
    -- | last_scrape_date          | date         | YES  |     | NULL                |                   |
    -- | next_scrape_date          | date         | YES  |     | NULL                |                   |
    -- | expected_scrape_frequency | varchar(255) | YES  |     | NULL                |                   |
    -- | dataset_name_prefix       | varchar(255) | YES  |     | NULL                |                   |
    -- | scrape_status             | varchar(255) | YES  |     | NULL                |                   |
    -- | pl_gather_task_id         | bigint       | YES  |     | NULL                |                   |

-- ALTER TABLE tmp_mo_1nf
--   ADD COLUMN md5_employee CHAR(32) NULL AFTER id, ADD INDEX(md5_employee),
--   ADD COLUMN employee_id BIGINT(20) NULL AFTER md5_employee, ADD INDEX(employee_id),
--   ADD COLUMN job_title_id BIGINT(20) NULL AFTER position_title, ADD INDEX(job_title_id),
--   ADD COLUMN md5_agency CHAR(32) NULL AFTER job_title_id, ADD INDEX(md5_agency),
--   ADD COLUMN agency_id BIGINT(20) NULL AFTER md5_agency, ADD INDEX(agency_id),
--   ADD COLUMN md5_ewy CHAR(32) NULL AFTER agency_id, ADD INDEX(md5_ewy),
--   ADD COLUMN ewy_id BIGINT(20) NULL AFTER md5_ewy, ADD INDEX(ewy_id),
--   ADD COLUMN md5_comp_gross_pay CHAR(32) NULL AFTER ewy_id, ADD INDEX(md5_comp_gross_pay),
--   ADD COLUMN comp_gross_pay_id BIGINT(20) NULL AFTER md5_comp_gross_pay, ADD INDEX(comp_gross_pay_id),
--   ADD COLUMN md5_address CHAR(32) NULL AFTER comp_gross_pay_id, ADD INDEX(md5_address),
--   ADD COLUMN address_id BIGINT(20) NULL AFTER md5_address, ADD INDEX(address_id),
--   ADD COLUMN agency_location_id BIGINT(20) NULL AFTER address_id, ADD INDEX(agency_location_id),
--   ADD COLUMN etl_id BIGINT(20) NULL AFTER agency_location_id, ADD INDEX(etl_id);

#= employees ==========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging with data from the temporary table
--    + Deal with employees that has no cleaned names
INSERT IGNORE INTO pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name, data_source_url, state, dataset_id, created_by)
SELECT t2.md5_employee, (f2.name_cleaned is not null), IFNULL(f2.name_cleaned, t2.full_name), t2.first_name, NULLIF(t2.middle_name, ''), t2.last_name,
       @data_source_url, 'MO', @dataset_id, @created_by
  FROM (SELECT t1.emp_name, t1.last_name, t1.first_name, t1.middle_name, t1.full_name, t1.md5_employee
          FROM tmp_mo_1nf t1
         GROUP BY t1.md5_employee) t2
       LEFT JOIN usa_raw.MO_public_employee_salary__emp_clean_names f2
       ON t2.emp_name = f2.name; -- 198_202 of 1_307_535 unique

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_mo_1nf t1
       LEFT JOIN pess_employees e1
       ON t1.md5_employee = e1.raw_employee_md5_hash
   SET t1.employee_id = e1.id;

-- -- 4. Update staging with data from the temporary table by hashes
-- --    + Deal with employees that has no cleaned names
-- UPDATE pess_employees e1
--        JOIN (SELECT t1.emp_name, t1.last_name, t1.first_name, t1.middle_name, t1.full_name, t1.employee_id
--                FROM tmp_mo_1nf t1
--               GROUP BY t1.employee_id) t2
--        ON e1.id = t2.employee_id
--        LEFT JOIN usa_raw.MO_public_employee_salary__emp_clean_names f2
--        ON t2.emp_name = f2.name
--    SET e1.cleaned         = (f2.name_cleaned is not null),
--        e1.full_name       = IFNULL(f2.name_cleaned, t2.full_name),
--        e1.first_name      = t2.first_name,
--        e1.middle_name     = NULLIF(t2.middle_name, ''),
--        e1.last_name       = t2.last_name,
--        e1.data_source_url = @data_source_url,
--        e1.state           = 'MO',
--        e1.dataset_id      = @dataset_id,
--        e1.created_by      = @created_by;

#= job_titles =========================================================================================================#
INSERT IGNORE INTO pess_job_titles (raw_job_title, cleaned, job_title, created_by)
SELECT position_title                     AS raw_job_title,
       (position_title_clean IS NOT NULL) AS cleaned,
       position_title_clean               AS job_title,
       @created_by                        AS created_by
  FROM usa_raw.MO_public_employee_salary__position_titles_clean;

UPDATE tmp_mo_1nf t1
       LEFT JOIN pess_job_titles j1
       ON REPLACE(
            REPLACE(
              REPLACE(t1.position_title,
                ' ','<>'),
              '><',''),
            '<>',' ') = j1.raw_job_title
   SET t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging
INSERT IGNORE INTO pess_agencies (raw_agency_md5_hash, raw_agency_name, data_source_url, dataset_id, created_by)
SELECT DISTINCT t1.md5_agency, t1.agency_name, @data_source_url, @dataset_id, @created_by
  FROM tmp_mo_1nf t1
 WHERE t1.md5_agency IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_mo_1nf t1
       LEFT JOIN pess_agencies a1
       ON t1.md5_agency = a1.raw_agency_md5_hash
   SET t1.agency_id = a1.id;

-- 4. Update staging with data from the temporary table by hashes
--    + Deal with agencies that has no cleaned names
UPDATE pess_agencies t1
       LEFT JOIN usa_raw.MO_public_employee_salary__agencies a1
       ON t1.raw_agency_name = a1.agency_name
   SET t1.cleaned     = (a1.agency_name_clean IS NOT NULL),
       t1.pl_org_id   = a1.pl_production_org_id,
       t1.agency_name = IFNULL(a1.agency_name_clean, t1.raw_agency_name),
       t1.limpar_uuid = a1.limpar_org_id
 WHERE t1.dataset_id = @dataset_id;

#= employee_work_years ================================================================================================#
-- 1. Calculating the hash in the temporary table
UPDATE tmp_mo_1nf
   SET md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, year, '', 'Salary', '',
                            ifnull(job_title_id, ''), @dataset_id, id, @data_source_url))
 WHERE gross_pay IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO pess_employee_work_years (md5_hash, employee_id, agency_id, year, job_title_id, raw_dataset_table_id_raw_id, raw_dataset_table_id, data_source_url, created_by, pay_type)
SELECT DISTINCT t1.md5_ewy, t1.employee_id, t1.agency_id, t1.year, t1.job_title_id, t1.id,
       @dataset_id, @data_source_url, @created_by, 'Salary'
  FROM tmp_mo_1nf t1
 WHERE t1.md5_ewy IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_mo_1nf t1
       JOIN pess_employee_work_years e1
       ON t1.md5_ewy = e1.md5_hash
   SET t1.ewy_id = e1.id;

-- -- 4. Update staging with data from the temporary table by hashes
-- UPDATE pess_employee_work_years e1
--        JOIN tmp_mo_1nf t1
--        ON e1.id = t1.ewy_id
--    SET e1.employee_id                 = t1.employee_id,
--        e1.agency_id                   = t1.agency_id,
--        e1.year                        = t1.year,
--        e1.pay_type                    = 'Salary',
--        e1.job_title_id                = t1.job_title_id,
--        e1.raw_dataset_table_id        = @dataset_id,
--        e1.raw_dataset_table_id_raw_id = t1.id,
--        e1.data_source_url             = @data_source_url,
--        e1.created_by                  = @created_by;

#= compensations ======================================================================================================#
#=========================== gross_pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'YTD GROSS');

-- 1. Calculating the hash in the temporary table
UPDATE tmp_mo_1nf
   SET md5_comp_gross_pay = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, gross_pay))
 WHERE gross_pay IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp_gross_pay, t1.ewy_id, @curr_comp_type_id, t1.gross_pay, 1, @dataset_id, @data_source_url, @created_by
    FROM tmp_mo_1nf t1
 WHERE t1.md5_comp_gross_pay IS NOT NULL;

-- -- 3. Transfer the obtained IDs to the temporary table
-- UPDATE tmp_mo_1nf t1
--        JOIN pess_compensations c1
--        ON t1.md5_comp_gross_pay = c1.md5_hash
--    SET t1.comp_gross_pay_id = c1.id;
--
-- -- 4. Update staging with data from the temporary table by hashes
-- UPDATE pess_compensations c1
--        JOIN tmp_mo_1nf t1
--        ON c1.id = t1.comp_gross_pay_id
--    SET c1.employee_work_year_id = t1.ewy_id,
--        c1.compensation_type_id  = @curr_comp_type_id,
--        c1.value                 = t1.gross_pay,
--        c1.is_total_compensation = 1,
--        c1.dataset_id            = @dataset_id,
--        c1.data_source_url       = t1.data_source_url,
--        c1.created_by            = @created_by;

#= addresses ==========================================================================================================#
-- 1. Calculating the hash in the temporary table
UPDATE tmp_mo_1nf t1
       JOIN usa_raw.MO_public_employee_salary__agencies a1
       ON t1.agency_name = a1.agency_name
   SET md5_address = MD5(CONCAT_WS('+', ifnull(a1.agency_name, ''),  ifnull(address, ''), ifnull(city, ''),
                     ifnull(state, ''), ifnull(zip, '')));

-- 2. Putting unique hashes into staging
INSERT INTO pess_addresses (raw_address_md5_hash, street_address, city, state, zip, created_by)
SELECT t2.md5_address, ua1.address, ua1.city, 'MO', ua1.zip, @created_by
  FROM (SELECT DISTINCT t1.md5_address, t1.agency_name
          FROM tmp_mo_1nf t1) t2
       JOIN usa_raw.MO_public_employee_salary__agencies ua1
       ON t2.agency_name = ua1.agency_name
 WHERE t2.md5_address IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_mo_1nf t1
       JOIN pess_addresses a1
       ON t1.md5_address = a1.raw_address_md5_hash
   SET t1.address_id = a1.id;

-- 4. Update staging with data from the temporary table by hashes
--
-- Не нравится мне эта двойная связь. Слишком запутанная и кажется, что необязательная.
-- Зачем вязать адреса с миллионом записей из темп-таблицы? нужно GROUP BY
--
-- UPDATE pess_addresses a1
--        JOIN (SELECT DISTINCT t1.address_id, t1.agency_name
--                FROM tmp_mo_1nf t1) t2
--        ON a1.id = t2.address_id
--        JOIN usa_raw.MO_public_employee_salary__agencies ua1
--        ON t2.agency_name = ua1.agency_name
--    SET a1.street_address = ua1.address,
--        a1.city           = ua1.city,
--        a1.state          = 'MO',
--        a1.zip            = ua1.zip,
--        a1.created_by     = @created_by;

#= agency_locations ===================================================================================================#
INSERT INTO pess_agency_locations (address_id, agency_id, data_source_url, created_by)
SELECT DISTINCT t1.address_id, t1.agency_id, @data_source_url, @created_by
  FROM tmp_mo_1nf t1
 WHERE t1.address_id IS NOT NULL;

UPDATE tmp_mo_1nf t1
       JOIN pess_agency_locations a1
       ON t1.address_id = a1.address_id
          AND t1.agency_id = a1.agency_id
   SET t1.agency_location_id = a1.id;

#= employee_to_locations ==============================================================================================#
INSERT INTO pess_employees_to_locations (employee_id, location_id, isolated_known_date, data_source_url, created_by)
SELECT DISTINCT t1.employee_id, t1.agency_location_id, t1.year, @data_source_url, @created_by
  FROM tmp_mo_1nf t1
 WHERE t1.address_id IS NOT NULL;

UPDATE tmp_mo_1nf t1
       JOIN pess_employees_to_locations e1
       ON t1.employee_id = e1.employee_id
          AND t1.agency_location_id = e1.location_id
          AND t1.year = e1.isolated_known_date
   SET t1.etl_id = e1.id;

#= employee_work_years ==============================================================================================#
UPDATE pess_employee_work_years e1
       JOIN tmp_mo_1nf t1
       ON e1.id = t1.ewy_id
   SET e1.employee_to_location_id = t1.etl_id,
       e1.location_id      = t1.agency_location_id
 WHERE t1.etl_id IS NOT NULL;
#= ========================================= WORKING FROM HERE =================================================================#
