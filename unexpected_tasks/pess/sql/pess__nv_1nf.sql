#= initiate variables, add new dataSET in DB ==========================================================================#

SET @created_by = 'Oleksii Kuts';

INSERT INTO pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url, created_by)
VALUES ('db01.usa_raw', 'nv_public_employee_salary%', 'Nevada Public Employee Salary', 'Scrape', 'https://transparentnevada.com/salaries/', @created_by);

SET @dataset_id = (SELECT id
                     FROM pess_raw_datasets
                    WHERE data_source_name = 'Nevada Public Employee Salary');

INSERT INTO pess_raw_dataset_tables(table_name, raw_dataset_id, created_by)
VALUES ('nv_public_employee_salary', @dataset_id, @created_by);

SET @dataset_id = (SELECT id
                     FROM pess_raw_dataset_tables
                    WHERE table_name = 'nv_public_employee_salary');

INSERT INTO pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
VALUES ('Regular pay', 0, 'Regular pay', @created_by),
       ('Overtime pay', 0, 'Overtime pay', @created_by),
       ('Other pay', 0, 'Other pay', @created_by),
       ('Total pay', 0, 'Total pay', @created_by),
       ('Total benefits', 0, 'Total benefits', @created_by),
       ('Total pay & benefits', 0, 'Total pay & benefits', @created_by)
    ON DUPLICATE KEY
UPDATE raw_compensation_type = raw_compensation_type;

#= create =============================================================================================================#

CREATE TABLE tmp_nv_1nf LIKE usa_raw.nv_public_employee_salary;

ALTER TABLE tmp_nv_1nf
     CHANGE `md5_hash` `md5_hash` VARCHAR(255); -- remove calculated logic for this field

INSERT INTO tmp_nv_1nf
SELECT *
  FROM usa_raw.nv_public_employee_salary
 WHERE agency NOT REGEXP '(school|academy|institute|college|university of|nshe)';

ALTER TABLE tmp_nv_1nf
    drop column created_at,
    drop column updated_at,
    drop column created_by,
    drop column scrape_dev_name,
    drop column scrape_frequency,
    drop column link,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column data_set_prefix,
    drop column scrape_status,
    drop column pl_gather_task_ID,
    drop column md5_hash,
    drop column run_id;

    -- | id                     | bigint        | NO   | PRI | NULL                                    | auto_increment                                |
    -- | year                   | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | full_name              | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | first_name             | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | middle_name            | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | last_name              | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | name_clean             | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | job_title              | varchar(255)  | YES  | MUL | NULL                                    |                                               |
    -- | job_title_clean        | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | agency                 | varchar(255)  | YES  |     | NULL                                    |                                               |
    -- | regular_pay            | decimal(65,2) | YES  |     | NULL                                    |                                               |
    -- | overtime_pay           | decimal(65,2) | YES  |     | NULL                                    |                                               |
    -- | other_pay              | decimal(65,2) | YES  |     | NULL                                    |                                               |
    -- | total_pay              | decimal(65,2) | YES  |     | NULL                                    |                                               |
    -- | total_benefits         | decimal(65,2) | YES  |     | NULL                                    |                                               |
    -- | total_pay_and_benefits | decimal(65,2) | YES  |     | NULL                                    |                                               |
    -- | data_source_url        | varchar(255)  | YES  |     | https://transparentnevada.com/salaries/ |                                               |


#= employees ==========================================================================================================#

ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_employee CHAR(32) NULL AFTER id, ADD INDEX(md5_employee);

UPDATE tmp_nv_1nf
SET md5_employee = MD5(CONCAT_WS('+', first_name, IFNULL(middle_name, ''), last_name, data_source_url));

INSERT IGNORE INTO pess_employees (raw_employee_md5_hash)
SELECT DISTINCT t1.md5_employee
  FROM tmp_nv_1nf t1; -- 173347 of 459047 unique

ALTER TABLE tmp_nv_1nf
  ADD COLUMN employee_id BIGINT(20) NULL AFTER md5_employee, ADD INDEX(employee_id);

UPDATE tmp_nv_1nf t1
       LEFT JOIN pess_employees e1
       ON t1.md5_employee = e1.raw_employee_md5_hash
   SET t1.employee_id = e1.id;

UPDATE pess_employees e1
       JOIN (SELECT t1.full_name, t1.employee_id, t1.data_source_url
               FROM tmp_nv_1nf t1
              GROUP BY t1.employee_id) t2
       ON e1.id = t2.employee_id
       JOIN usa_raw.nv_public_employee_salary__names_clean f2
       ON t2.full_name = f2.full_name
   SET e1.cleaned         = 1,
       e1.full_name       = f2.full_name_clean,
       e1.first_name      = f2.first_name,
       e1.middle_name     = NULLIF(f2.middle_name, ''),
       e1.last_name       = f2.last_name,
       e1.suffix          = f2.suffix,
       e1.data_source_url = t2.data_source_url,
       e1.state           = 'NV',
       e1.dataset_id      = @dataset_id,
       e1.created_by      = @created_by;

#= job_titles =========================================================================================================#
INSERT IGNORE INTO pess_job_titles (raw_job_title, cleaned, job_title, created_by)
SELECT job_title                         AS raw_job_title,
       (job_title_clean IS NOT NULL)     AS cleaned,
       job_title_clean                   AS job_title,
       @created_by                       AS created_by
  FROM usa_raw.nv_public_employee_salary__job_titles_clean;

ALTER TABLE tmp_nv_1nf
  ADD COLUMN job_title_id BIGINT(20) NULL AFTER job_title, ADD INDEX(job_title_id);

UPDATE tmp_nv_1nf t1
       LEFT JOIN pess_job_titles j1
       ON t1.job_title = j1.raw_job_title
   SET t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_agency CHAR(32) NULL AFTER job_title_id, ADD INDEX(md5_agency);

-- 1. Считаем хеш во временной таблице
UPDATE tmp_nv_1nf t1
   SET t1.md5_agency = MD5(CONCAT_WS('+', agency, data_source_url))
 WHERE t1.agency IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT IGNORE INTO pess_agencies (raw_agency_md5_hash)
SELECT DISTINCT t1.md5_agency
  FROM tmp_nv_1nf t1
 WHERE t1.md5_agency IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN agency_id BIGINT(20) NULL AFTER md5_agency, ADD INDEX(agency_id);

UPDATE tmp_nv_1nf t1
       LEFT JOIN pess_agencies a1
       ON t1.md5_agency = a1.raw_agency_md5_hash
   SET t1.agency_id = a1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_agencies a1
       JOIN (SELECT t1.agency_id, t1.agency, t1.data_source_url
               FROM tmp_nv_1nf t1
              GROUP BY t1.agency_id) t2
       ON a1.id = t2.agency_id
   SET a1.raw_agency_name = t2.agency,
       a1.cleaned         = TRUE,
       a1.agency_name     = t2.agency,
       a1.dataset_id      = @dataset_id,
       a1.data_source_url = t2.data_source_url,
       a1.created_by      = @created_by;

UPDATE pess_agencies t1
       JOIN usa_raw.nv_public_employee_salary_uniq_agencies a1
       ON t1.raw_agency_name = a1.agency_name
   SET t1.pl_org_id = a1.pl_production_org_id
 WHERE t1.dataset_id = @dataset_id;

#= employee_work_years ================================================================================================#
-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_ewy CHAR(32) NULL AFTER agency_id, ADD INDEX(md5_ewy);

UPDATE tmp_nv_1nf
   SET md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, year, '', 'Salary', '',
                            ifnull(job_title_id, ''), @dataset_id, id, data_source_url))
 WHERE total_pay_and_benefits IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_employee_work_years (md5_hash)
SELECT DISTINCT t1.md5_ewy
  FROM tmp_nv_1nf t1
 WHERE t1.md5_ewy IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN ewy_id BIGINT(20) NULL AFTER md5_ewy, ADD INDEX(ewy_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_employee_work_years e1
       ON t1.md5_ewy = e1.md5_hash
   SET t1.ewy_id = e1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_employee_work_years e1
       JOIN tmp_nv_1nf t1
       ON e1.id = t1.ewy_id
   SET e1.employee_id                 = t1.employee_id,
       e1.agency_id                   = t1.agency_id,
       e1.year                        = t1.year,
       e1.pay_type                    = 'Salary',
       e1.job_title_id                = t1.job_title_id,
       e1.raw_dataset_table_id        = @dataset_id,
       e1.raw_dataset_table_id_raw_id = t1.id,
       e1.data_source_url             = t1.data_source_url,
       e1.created_by                  = @created_by;

#= 924_373

#= compensations ======================================================================================================#
#=========================== regular_pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Regular pay');

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_comp_regular_pay CHAR(32) NULL AFTER ewy_id, ADD INDEX(md5_comp_regular_pay);

UPDATE tmp_nv_1nf
   SET md5_comp_regular_pay = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, regular_pay))
 WHERE regular_pay IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_compensations (md5_hash)
SELECT DISTINCT t1.md5_comp_regular_pay
  FROM tmp_nv_1nf t1
 WHERE t1.md5_comp_regular_pay IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN comp_regular_pay_id BIGINT(20) NULL AFTER md5_comp_regular_pay, ADD INDEX(comp_regular_pay_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_compensations c1
       ON t1.md5_comp_regular_pay = c1.md5_hash
   SET t1.comp_regular_pay_id = c1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_compensations c1
       JOIN tmp_nv_1nf t1
       ON c1.id = t1.comp_regular_pay_id
   SET c1.employee_work_year_id = t1.ewy_id,
       c1.compensation_type_id  = @curr_comp_type_id,
       c1.value                 = t1.regular_pay,
       c1.is_total_compensation = 0,
       c1.dataset_id            = @dataset_id,
       c1.data_source_url       = t1.data_source_url,
       c1.created_by            = @created_by;

#=========================== overtime_pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Overtime pay');

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_comp_overtime_pay CHAR(32) NULL AFTER comp_regular_pay_id, ADD INDEX(md5_comp_overtime_pay);

UPDATE tmp_nv_1nf
   SET md5_comp_overtime_pay = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, overtime_pay))
 WHERE overtime_pay IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_compensations (md5_hash)
SELECT DISTINCT t1.md5_comp_overtime_pay
  FROM tmp_nv_1nf t1
 WHERE t1.md5_comp_overtime_pay IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN comp_overtime_pay_id BIGINT(20) NULL AFTER md5_comp_overtime_pay, ADD INDEX(comp_overtime_pay_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_compensations c1
       ON t1.md5_comp_overtime_pay = c1.md5_hash
   SET t1.comp_overtime_pay_id = c1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_compensations c1
       JOIN tmp_nv_1nf t1
       ON c1.id = t1.comp_overtime_pay_id
   SET c1.employee_work_year_id = t1.ewy_id,
       c1.compensation_type_id  = @curr_comp_type_id,
       c1.value                 = t1.overtime_pay,
       c1.is_total_compensation = 0,
       c1.dataset_id            = @dataset_id,
       c1.data_source_url       = t1.data_source_url,
       c1.created_by            = @created_by;

#=========================== other_pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Other pay');

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_comp_other_pay CHAR(32) NULL AFTER comp_overtime_pay_id, ADD INDEX(md5_comp_other_pay);

UPDATE tmp_nv_1nf
   SET md5_comp_other_pay = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, other_pay))
 WHERE other_pay IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_compensations (md5_hash)
SELECT DISTINCT t1.md5_comp_other_pay
  FROM tmp_nv_1nf t1
 WHERE t1.md5_comp_other_pay IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN comp_other_pay_id BIGINT(20) NULL AFTER md5_comp_other_pay, ADD INDEX(comp_other_pay_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_compensations c1
       ON t1.md5_comp_other_pay = c1.md5_hash
   SET t1.comp_other_pay_id = c1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_compensations c1
       JOIN tmp_nv_1nf t1
       ON c1.id = t1.comp_other_pay_id
   SET c1.employee_work_year_id = t1.ewy_id,
       c1.compensation_type_id  = @curr_comp_type_id,
       c1.value                 = t1.other_pay,
       c1.is_total_compensation = 0,
       c1.dataset_id            = @dataset_id,
       c1.data_source_url       = t1.data_source_url,
       c1.created_by            = @created_by;

#=========================== total_pay ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Total pay');

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_comp_total_pay CHAR(32) NULL AFTER comp_other_pay_id, ADD INDEX(md5_comp_total_pay);

UPDATE tmp_nv_1nf
   SET md5_comp_total_pay = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, total_pay))
 WHERE total_pay IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_compensations (md5_hash)
SELECT DISTINCT t1.md5_comp_total_pay
  FROM tmp_nv_1nf t1
 WHERE t1.md5_comp_total_pay IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN comp_total_pay_id BIGINT(20) NULL AFTER md5_comp_total_pay, ADD INDEX(comp_total_pay_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_compensations c1
       ON t1.md5_comp_total_pay = c1.md5_hash
   SET t1.comp_total_pay_id = c1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_compensations c1
       JOIN tmp_nv_1nf t1
       ON c1.id = t1.comp_total_pay_id
   SET c1.employee_work_year_id = t1.ewy_id,
       c1.compensation_type_id  = @curr_comp_type_id,
       c1.value                 = t1.total_pay,
       c1.is_total_compensation = 1,
       c1.dataset_id            = @dataset_id,
       c1.data_source_url       = t1.data_source_url,
       c1.created_by            = @created_by;

#=========================== total_benefits ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Total benefits');

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_comp_total_benefits CHAR(32) NULL AFTER comp_total_pay_id, ADD INDEX(md5_comp_total_benefits);

UPDATE tmp_nv_1nf
   SET md5_comp_total_benefits = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, total_benefits))
 WHERE total_benefits IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_compensations (md5_hash)
SELECT DISTINCT t1.md5_comp_total_benefits
  FROM tmp_nv_1nf t1
 WHERE t1.md5_comp_total_benefits IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN comp_total_benefits_id BIGINT(20) NULL AFTER md5_comp_total_benefits, ADD INDEX(comp_total_benefits_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_compensations c1
       ON t1.md5_comp_total_benefits = c1.md5_hash
   SET t1.comp_total_benefits_id = c1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_compensations c1
       JOIN tmp_nv_1nf t1
       ON c1.id = t1.comp_total_benefits_id
   SET c1.employee_work_year_id = t1.ewy_id,
       c1.compensation_type_id  = @curr_comp_type_id,
       c1.value                 = t1.total_benefits,
       c1.is_total_compensation = 0,
       c1.dataset_id            = @dataset_id,
       c1.data_source_url       = t1.data_source_url,
       c1.created_by            = @created_by;

#=========================== total_pay_and_benefits ==============================================================================#
SET @curr_comp_type_id =
    (SELECT id
       FROM pess_compensation_types
      WHERE raw_compensation_type = 'Total pay & benefits');

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_comp_total_pay_and_benefits CHAR(32) NULL AFTER comp_total_benefits_id, ADD INDEX(md5_comp_total_pay_and_benefits);

UPDATE tmp_nv_1nf
   SET md5_comp_total_pay_and_benefits = MD5(CONCAT_WS('+', ewy_id, @curr_comp_type_id, total_pay_and_benefits))
 WHERE total_pay_and_benefits IS NOT NULL;

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_compensations (md5_hash)
SELECT DISTINCT t1.md5_comp_total_pay_and_benefits
  FROM tmp_nv_1nf t1
 WHERE t1.md5_comp_total_pay_and_benefits IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN comp_total_pay_and_benefits_id BIGINT(20) NULL AFTER md5_comp_total_pay_and_benefits, ADD INDEX(comp_total_pay_and_benefits_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_compensations c1
       ON t1.md5_comp_total_pay_and_benefits = c1.md5_hash
   SET t1.comp_total_pay_and_benefits_id = c1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_compensations c1
       JOIN tmp_nv_1nf t1
       ON c1.id = t1.comp_total_pay_and_benefits_id
   SET c1.employee_work_year_id = t1.ewy_id,
       c1.compensation_type_id  = @curr_comp_type_id,
       c1.value                 = t1.total_pay_and_benefits,
       c1.is_total_compensation = 0,
       c1.dataset_id            = @dataset_id,
       c1.data_source_url       = t1.data_source_url,
       c1.created_by            = @created_by;

#= addresses ==========================================================================================================#
-- 1. Считаем хеш во временной таблице
-- 2. Заносим уникальные хеши в стейджинг
-- 3. Переносим полученные АйДишники во временную таблицу
-- 4. Обновляем стейджинг данными из временной таблицы по хешам

-- 1. Считаем хеш во временной таблице
ALTER TABLE tmp_nv_1nf
  ADD COLUMN md5_address CHAR(32) NULL AFTER comp_total_pay_and_benefits_id, ADD INDEX(md5_address);

UPDATE tmp_nv_1nf t1
       JOIN usa_raw.nv_public_employee_salary_uniq_agencies a1
       ON t1.agency = a1.agency_name
   SET md5_address = MD5(CONCAT_WS('+', ifnull(agency_name, ''),  ifnull(street_address, ''), ifnull(city, ''),
                     ifnull(state, ''), ifnull(zip, '')));

-- 2. Заносим уникальные хеши в стейджинг
INSERT INTO pess_addresses (raw_address_md5_hash)
SELECT DISTINCT t1.md5_address
  FROM tmp_nv_1nf t1
 WHERE t1.md5_address IS NOT NULL;

-- 3. Переносим полученные АйДишники во временную таблицу
ALTER TABLE tmp_nv_1nf
  ADD COLUMN address_id BIGINT(20) NULL AFTER md5_address, ADD INDEX(address_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_addresses a1
       ON t1.md5_address = a1.raw_address_md5_hash
   SET t1.address_id = a1.id;

-- 4. Обновляем стейджинг данными из временной таблицы по хешам
UPDATE pess_addresses a1
       JOIN (SELECT t1.address_id, t1.agency
               FROM tmp_nv_1nf t1) t2
       ON a1.id = t2.address_id
       JOIN usa_raw.nv_public_employee_salary_uniq_agencies ua1
       ON t2.agency = ua1.agency_name
   SET a1.street_address = ua1.street_address,
       a1.city           = ua1.city,
       a1.state          = 'NV',
       a1.zip            = ua1.zip,
       a1.created_by     = @created_by;

#= agency_locations ===================================================================================================#
INSERT INTO pess_agency_locations (address_id, agency_id, data_source_url, created_by)
SELECT DISTINCT t1.address_id, t1.agency_id, t1.data_source_url, @created_by
  FROM tmp_nv_1nf t1
 WHERE t1.address_id IS NOT NULL;

ALTER TABLE tmp_nv_1nf
  ADD COLUMN agency_location_id BIGINT(20) NULL AFTER address_id, ADD INDEX(agency_location_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_agency_locations a1
       ON t1.address_id = a1.address_id
          AND t1.agency_id = a1.agency_id
   SET t1.agency_location_id = a1.id;

#= employee_to_locations ==============================================================================================#
INSERT INTO pess_employees_to_locations (employee_id, agency_location_id, isolated_known_date, data_source_url, created_by)
SELECT DISTINCT t1.employee_id, t1.agency_location_id, t1.year, t1.data_source_url, @created_by
  FROM tmp_nv_1nf t1
 WHERE t1.address_id IS NOT NULL;

ALTER TABLE tmp_nv_1nf
  ADD COLUMN etl_id BIGINT(20) NULL AFTER agency_location_id, ADD INDEX(etl_id);

UPDATE tmp_nv_1nf t1
       JOIN pess_employees_to_locations e1
       ON t1.employee_id = e1.employee_id
          AND t1.agency_location_id = e1.agency_location_id
          AND t1.year = e1.isolated_known_date
   SET t1.etl_id = e1.id;

#= employee_work_years ==============================================================================================#
UPDATE pess_employee_work_years e1
       JOIN tmp_nv_1nf t1
       ON e1.id = t1.ewy_id
   SET e1.employee_to_location_id = t1.etl_id,
       e1.agency_location_id      = t1.agency_location_id
 WHERE t1.etl_id IS NOT NULL;

#= ========================================= WORKING FROM HERE =================================================================#
