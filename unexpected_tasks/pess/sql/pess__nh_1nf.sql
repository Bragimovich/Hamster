#= initiate variables, add new dataSET in DB ==========================================================================#

SET @created_by = 'Oleksii Kuts';

SET @data_source_url = 'https://www.nh.gov/transparentnh/search/index.htm';

SET @dataset_already_inserted = (SELECT id
                                   FROM test_raw_datasets
                                  WHERE data_source_name = 'State of New Hampshire Public Employees Salaries');

INSERT INTO test_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url, created_by)
SELECT 'db01.state_salaries__raw', 'nh_public_employee_salaries%', 'State of New Hampshire Public Employees Salaries', 'Scrape', @data_source_url, @created_by
 WHERE @dataset_already_inserted IS NULL;

SET @dataset_id = (SELECT id
                     FROM test_raw_datasets
                    WHERE data_source_name = 'State of New Hampshire Public Employees Salaries');

SET @dataset_already_inserted = (SELECT id
                                   FROM test_raw_dataset_tables
                                  WHERE table_name = 'nh_public_employee_salaries');

INSERT INTO test_raw_dataset_tables(table_name, raw_dataset_id, created_by)
SELECT 'nh_public_employee_salaries', @dataset_id, @created_by
 WHERE @dataset_already_inserted IS NULL;

SET @dataset_id = (SELECT id
                     FROM test_raw_dataset_tables
                    WHERE table_name = 'nh_public_employee_salaries');

INSERT INTO test_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
VALUES ('Regular pay', 0, 'Regular pay', @created_by),
       ('Overtime Pay', 0, 'Overtime pay', @created_by),
       ('Other Pay', 0, 'Other pay', @created_by),
       ('None', 0, 'None', @created_by),
       ('Holiday Pay', 0, 'Holiday Pay', @created_by),
       ('Reportable Fringe Benefit', 0, 'Reportable Fringe Benefit', @created_by),
       ('Special Duty', 0, 'Special Duty', @created_by)
    ON DUPLICATE KEY
UPDATE raw_compensation_type = raw_compensation_type;
-- | Regular Pay               |   201778 |
-- | Overtime                  |    87467 |
-- | Other Pay Item            |    86196 |
-- | None                      |     6223 | new
-- | Holiday Pay               |   134124 | new
-- | Reportable Fringe Benefit |    20156 | new
-- | Special Duty              |     4341 | new

SELECT @created_by, @data_source_url, @dataset_id;

#= create =============================================================================================================#
CREATE TABLE IF NOT EXISTS tmp_nh_1nf LIKE state_salaries__raw.nh_public_employee_salaries;

ALTER TABLE tmp_nh_1nf
      DROP COLUMN internal_employee_id,
      DROP COLUMN created_by,
      DROP COLUMN created_at,
      DROP COLUMN updated_at,
      DROP COLUMN run_id,
      DROP COLUMN touched_run_id,
      DROP COLUMN deleted,
      DROP COLUMN md5_hash;

ALTER TABLE tmp_nh_1nf
      MODIFY COLUMN employee_full_name_concat VARCHAR(255);

-- | id                        | bigint(20)   | NO   | PRI | NULL              | auto_increment              |
-- | year                      | int(11)      | YES  |     | NULL              |                             |
-- | employee_last_name        | varchar(255) | YES  |     | NULL              |                             |
-- | employee_first_name       | varchar(255) | YES  |     | NULL              |                             |
-- | employee_middle_initial   | varchar(255) | YES  |     | NULL              |                             |
-- | employee_full_name_concat | varchar(255) | YES  |     | NULL              | STORED GENERATED            |
-- | title                     | varchar(255) | YES  |     | NULL              |                             |
-- | pay_category              | varchar(255) | YES  |     | NULL              |                             |
-- | agency                    | varchar(255) | YES  |     | NULL              |                             |
-- | annual_salary             | varchar(255) | YES  |     | NULL              |                             |
-- | internal_employee_id      | bigint(20)   | YES  |     | NULL              |                             |
-- | status                    | varchar(255) | YES  |     | NULL              |                             |
-- | data_source_url           | text         | YES  |     | NULL              |                             |
-- | created_by                | varchar(255) | YES  |     | Abdul Wahab       |                             |
-- | created_at                | datetime     | YES  |     | CURRENT_TIMESTAMP |                             |
-- | updated_at                | datetime     | NO   |     | CURRENT_TIMESTAMP | on update CURRENT_TIMESTAMP |
-- | run_id                    | bigint(20)   | YES  | MUL | NULL              |                             |
-- | touched_run_id            | bigint(20)   | YES  | MUL | NULL              |                             |
-- | deleted                   | tinyint(1)   | YES  | MUL | 0                 |                             |
-- | md5_hash                  | varchar(255) | YES  | UNI | NULL              |                             |

ALTER TABLE tmp_nh_1nf
  ADD COLUMN md5_employee CHAR(32) NULL AFTER id, ADD INDEX(md5_employee),
  ADD COLUMN employee_id BIGINT(20) NULL AFTER md5_employee, ADD INDEX(employee_id),
  ADD COLUMN job_title_id BIGINT(20) NULL AFTER employee_id,
  ADD COLUMN md5_agency CHAR(32) NULL AFTER job_title_id, ADD INDEX(md5_agency),
  ADD COLUMN agency_id BIGINT(20) NULL AFTER md5_agency, ADD INDEX(agency_id),
  ADD COLUMN md5_ewy CHAR(32) NULL AFTER agency_id, ADD INDEX(md5_ewy),
  ADD COLUMN ewy_id BIGINT(20) NULL AFTER md5_ewy, ADD INDEX(ewy_id),
  ADD COLUMN md5_comp CHAR(32) NULL AFTER ewy_id, ADD INDEX(md5_comp),
  ADD COLUMN comp_id BIGINT(20) NULL AFTER md5_comp;

#= insert =============================================================================================================#
INSERT INTO tmp_nh_1nf (year, employee_last_name, employee_first_name, employee_middle_initial, employee_full_name_concat, title, pay_category, agency, annual_salary, status, data_source_url, md5_employee, md5_agency)
SELECT s1.year, s1.employee_last_name, s1.employee_first_name, s1.employee_middle_initial, s1.employee_full_name_concat, s1.title, s1.pay_category, s1.agency, s1.annual_salary, s1.status, @data_source_url,
       MD5(CONCAT_WS('+', s1.employee_full_name_concat, s1.agency, s1.title, @data_source_url)),
       MD5(CONCAT_WS('+', s1.agency, @data_source_url))
  FROM state_salaries__raw.nh_public_employee_salaries s1
 WHERE s1.agency NOT REGEXP '(educ|univers|instit|coll|academ|school|unknown|^$)'; -- 531_515
       -- AND emp_name NOT REGEXP '(^PROTECTED|^CLIENT)';

#= employees ==========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging with data from the temporary table
--    + Deal with employees that has no cleaned names
INSERT IGNORE INTO test_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name, data_source_url, state, dataset_id, created_by)
SELECT t2.md5_employee, (c2.employee_full_name_concat_clean is not null), IFNULL(c2.employee_full_name_concat_clean, t2.employee_full_name_concat), t2.employee_first_name, NULLIF(t2.employee_middle_initial, ''), t2.employee_last_name,
       @data_source_url, 'NH', @dataset_id, @created_by
  FROM (SELECT t1.employee_full_name_concat, t1.employee_first_name, t1.employee_middle_initial, t1.employee_last_name, t1.md5_employee
          FROM tmp_nh_1nf t1
         GROUP BY t1.md5_employee) t2
       LEFT JOIN state_salaries__raw.nh_public_employee_salaries__names_clean c2
       ON t2.employee_full_name_concat = c2.employee_full_name_concat; -- 81_130 of 531_515

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_nh_1nf t1
       LEFT JOIN test_employees e1
       ON t1.md5_employee = e1.raw_employee_md5_hash
   SET t1.employee_id = e1.id;

#= job_titles =========================================================================================================#
INSERT IGNORE INTO test_job_titles (raw_job_title, cleaned, job_title, created_by)
SELECT j1.title                     AS raw_job_title,
       (j1.title_clean IS NOT NULL) AS cleaned,
       j1.title_clean               AS job_title,
       @created_by                  AS created_by
  FROM state_salaries__raw.nh_public_employee_salaries__title_clean j1
       JOIN (SELECT DISTINCT title FROM tmp_nh_1nf) t1
       ON j1.title = t1.title; -- 2_605 (319 dups)

UPDATE tmp_nh_1nf t1
       LEFT JOIN test_job_titles j1
       ON t1.title = j1.raw_job_title
   SET t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#
-- 1. Calculating the hash in the temporary table (moved to INSERT section)

-- 2. Putting unique hashes into staging
INSERT IGNORE INTO test_agencies (raw_agency_md5_hash, raw_agency_name, data_source_url, dataset_id, created_by)
SELECT DISTINCT t1.md5_agency, t1.agency, @data_source_url, @dataset_id, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.md5_agency IS NOT NULL; -- 117

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_nh_1nf t1
       LEFT JOIN test_agencies a1
       ON t1.md5_agency = a1.raw_agency_md5_hash
   SET t1.agency_id = a1.id;

-- 4. Update staging with data from the temporary table by hashes
--    + Deal with agencies that has no cleaned names
UPDATE test_agencies t1
       LEFT JOIN  state_salaries__raw.nh_public_employee_salaries__agency_clean s1
       ON t1.raw_agency_name = s1.agency
   SET t1.cleaned     = (s1.agency_clean IS NOT NULL),
       t1.pl_org_id   = NULL,
       t1.agency_name = IFNULL(s1.agency_clean, t1.raw_agency_name),
       t1.limpar_uuid = NULL
 WHERE t1.dataset_id = @dataset_id;

#= employee_work_years ================================================================================================#
-- 1. Calculating the hash in the temporary table
UPDATE tmp_nh_1nf
   SET md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, year, '', 'Salary', '',
                            ifnull(job_title_id, ''), @dataset_id, id, @data_source_url))
 WHERE annual_salary IS NOT NULL;

-- 2. Putting unique hashes into staging
INSERT INTO test_employee_work_years (md5_hash, employee_id, agency_id, year, job_title_id, raw_dataset_table_id_raw_id, raw_dataset_table_id, data_source_url, created_by, pay_type)
SELECT DISTINCT t1.md5_ewy, t1.employee_id, t1.agency_id, t1.year, t1.job_title_id, t1.id,
       @dataset_id, @data_source_url, @created_by, 'Salary'
  FROM tmp_nh_1nf t1
 WHERE t1.md5_ewy IS NOT NULL;

-- 3. Transfer the obtained IDs to the temporary table
UPDATE tmp_nh_1nf t1
       JOIN test_employee_work_years e1
       ON t1.md5_ewy = e1.md5_hash
   SET t1.ewy_id = e1.id;

#= compensations ======================================================================================================#
-- 1. Calculating the hash in the temporary table
UPDATE tmp_nh_1nf
   SET md5_comp = MD5(CONCAT_WS('+', ewy_id, pay_category, annual_salary, @dataset_id, @data_source_url))
 WHERE annual_salary IS NOT NULL;

#= ========================================= WORKING FROM HERE =================================================================#
#=========================== Regular pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'Regular pay');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'Regular Pay'; -- 198_232

#=========================== Overtime Pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'Overtime Pay');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'Overtime'; -- 87_201

#=========================== Other Pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'Other Pay');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'Other Pay Item'; -- 84_470

#=========================== None ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'None');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'None'; -- 6_082

#=========================== Holiday Pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'Holiday Pay');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'Holiday Pay'; -- 131_038

#=========================== Reportable Fringe Benefit ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'Reportable Fringe Benefit');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'Reportable Fringe Benefit'; -- 20_151

#=========================== Special Duty ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM test_compensation_types
      WHERE raw_compensation_type = 'Special Duty');

SELECT @curr_comp_type_id;

-- 2. Putting unique hashes into staging
INSERT INTO test_compensations (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url, created_by)
SELECT t1.md5_comp, t1.ewy_id, @curr_comp_type_id, t1.annual_salary, FALSE, @dataset_id, @data_source_url, @created_by
  FROM tmp_nh_1nf t1
 WHERE t1.pay_category = 'Special Duty'; -- 4_341

#= addresses ==========================================================================================================#
#= we DO NOT HAVE addresses ==========================================================================================================#
-- -- 1. Calculating the hash in the temporary table
-- UPDATE tmp_nh_1nf t1
--        JOIN  state_salaries__raw.virginia_public_agency a1
--        ON t1.agency = a1.name
--    SET md5_address = MD5(CONCAT_WS('+', ifnull(a1.name, ''),  ifnull(@address, ''), ifnull(@city, ''),
--                      ifnull(@state, ''), ifnull(@zip, '')));
--
-- -- 2. Putting unique hashes into staging
-- INSERT INTO test_addresses (raw_address_md5_hash, street_address, city, state, zip, created_by)
-- -- SELECT t2.md5_address, ua1.address, ua1.city, 'VA', ua1.zip, @created_by
-- SELECT DISTINCT t2.md5_address, NULL, NULL, 'VA', NULL, @created_by
--   FROM (SELECT DISTINCT t1.md5_address, t1.agency
--           FROM tmp_nh_1nf t1) t2
--        JOIN  state_salaries__raw.virginia_public_agency ua1
--        ON t2.agency = ua1.name
--  WHERE t2.md5_address IS NOT NULL;
--
-- -- 3. Transfer the obtained IDs to the temporary table
-- UPDATE tmp_nh_1nf t1
--        JOIN test_addresses a1
--        ON t1.md5_address = a1.raw_address_md5_hash
--    SET t1.address_id = a1.id;
--
-- #= agency_locations ===================================================================================================#
-- INSERT INTO test_agency_locations (address_id, agency_id, data_source_url, created_by)
-- SELECT DISTINCT t1.address_id, t1.agency_id, @data_source_url, @created_by
--   FROM tmp_nh_1nf t1
--  WHERE t1.address_id IS NOT NULL;
--
-- UPDATE tmp_nh_1nf t1
--        JOIN test_agency_locations a1
--        ON t1.address_id = a1.address_id
--           AND t1.agency_id = a1.agency_id
--    SET t1.agency_location_id = a1.id;
--
-- #= employee_to_locations ==============================================================================================#
-- INSERT INTO test_employees_to_locations (employee_id, agency_location_id, isolated_known_date, data_source_url, created_by)
-- SELECT DISTINCT t1.employee_id, t1.agency_location_id, t1.year, @data_source_url, @created_by
--   FROM tmp_nh_1nf t1
--  WHERE t1.address_id IS NOT NULL;
--
-- UPDATE tmp_nh_1nf t1
--        JOIN test_employees_to_locations e1
--        ON t1.employee_id = e1.employee_id
--           AND t1.agency_location_id = e1.agency_location_id
--           AND t1.year = e1.isolated_known_date
--    SET t1.etl_id = e1.id;
--
-- #= employee_work_years ==============================================================================================#
-- UPDATE test_employee_work_years e1
--        JOIN tmp_nh_1nf t1
--        ON e1.id = t1.ewy_id
--    SET e1.employee_to_location_id = t1.etl_id,
--        e1.agency_location_id      = t1.agency_location_id
--  WHERE t1.etl_id IS NOT NULL;
