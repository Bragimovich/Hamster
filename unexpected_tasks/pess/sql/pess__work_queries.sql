ALTER TABLE pess_employees_to_addresses
    ADD COLUMN relation_md5_hash VARCHAR(255)
        GENERATED ALWAYS AS (MD5(CONCAT_WS('', employee_id, address_id, address_employee_association_type_id,
                                           start_month, start_day_of_month,
                                           start_year, end_month, end_day_of_month, end_year,
                                           isolated_known_date))) STORED;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_addresses;
SET FOREIGN_KEY_CHECKS = 1;
#= agency ==============================================================================================================

update pess_agencies pa
set pa.raw_agency_md5_hash = MD5(CONCAT_WS('+', raw_agency_name, data_source_url));

#=======================================================================================================================
DELETE
FROM pess_job_titles;
ALTER TABLE pess_job_titles
    AUTO_INCREMENT = 1;

# 2246
select count(distinct job)
from usa_raw.michigan_public_employee_salary;

insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select j1.job                                                                      as raw_job_title,
       if(m1.job is not null or (m1.job_cleaned is null and j1.job is null), 1, 0) as cleaned,
       if(m1.job_cleaned is null and m1.job is null, j1.job, m1.job_cleaned)       as job_title
from (select distinct job from usa_raw.michigan_public_employee_salary) j1
         left join usa_raw.michigan_puplic_employee_salary__jobs m1
                   on j1.job <=> m1.job;
#=======================================================================================================================
DELETE
FROM pess_addresses;
ALTER TABLE pess_addresses
    AUTO_INCREMENT = 1;

select md5(concat_ws('', NULL)), md5(concat_ws('', NULL, NULL));

insert ignore into pess_addresses (raw_address_md5_hash, city, county, state)
select distinct MD5(CONCAT_WS('', city, county, state)),
                city,
                county,
                state
from usa_raw.michigan_public_employee_salary_uniq_orgs;
#=======================================================================================================================
DELETE
FROM pess_employees;
ALTER TABLE pess_employees
    AUTO_INCREMENT = 1;

insert into pess_employees (raw_employee_md5_hash, full_name, first_name, last_name, middle_name, data_source_url)
select distinct MD5(CONCAT_WS('', full_name, first_name, middle_name, last_name, data_source_url)),
                full_name,
                first_name,
                last_name,
                middle_name,
                data_source_url
from usa_raw.michigan_public_employee_salary;
#=======================================================================================================================
DELETE
FROM pess_employees_to_addresses;
ALTER TABLE pess_employees_to_addresses
    AUTO_INCREMENT = 1;

select e1.id as employee_id,
       a1.id as address_id,
       1,
       t1.year
from tmp_mi_1nf__old t1
         left join pess_employees e1
                   on t1.md5_employee = e1.raw_employee_md5_hash
         left join pess_addresses a1
                   on t1.md5_address = a1.raw_address_md5_hash;

update pess_employees_to_addresses
set md5_hash = null;

update pess_employees_to_addresses
set md5_hash = MD5(CONCAT_WS(' ', employee_id, address_id, address_employee_association_type_id, start_month,
                             start_day_of_month, start_year, end_month, end_day_of_month, end_year,
                             isolated_known_date));

select CONCAT_WS(' ', employee_id, address_id, address_employee_association_type_id, start_month,
                 start_day_of_month, start_year, end_month, end_day_of_month, end_year,
                 isolated_known_date)
from pess_employees_to_addresses;
#=======================================================================================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees_to_locations;
SET FOREIGN_KEY_CHECKS = 1;

select t1.employee_id, t1.agency_location_id, t1.year
from tmp_mi_1nf__old t1
where t1.salary is not null;

select distinct t1.employee_id, t1.agency_location_id, t1.year
from tmp_mi_1nf__old t1
where t1.salary is not null;

insert into pess_employees_to_locations (employee_id, location_id, isolated_known_date)
select distinct t1.employee_id, t1.agency_location_id, t1.year
from tmp_mi_1nf__old t1
where t1.salary is not null;

update pess_employees_to_locations
set md5_hash = null;

select CONCAT_WS(' ', employee_id, location_id, start_month,
                 start_day_of_month, start_year, end_month, end_day_of_month, end_year,
                 isolated_known_date)
from pess_employees_to_locations;

update pess_employees_to_locations
set md5_hash = MD5(CONCAT_WS(' ', employee_id, location_id, start_month,
                             start_day_of_month, start_year, end_month, end_day_of_month, end_year,
                             isolated_known_date));
#=======================================================================================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employee_work_years;
SET FOREIGN_KEY_CHECKS = 1;

select t1.employee_to_location_id, t1.agency_location_id, t1.agency_id, t1.year, t1.job, t1.id
from tmp_mi_1nf__old t1
where t1.salary is not null;

select distinct t1.employee_to_location_id,
                t1.agency_location_id,
                t1.agency_id,
                t1.year,
                'Salary',
                t1.job_title_id,
                1,
                t1.id
from tmp_mi_1nf__old t1
where t1.salary is not null;

insert into pess_employee_work_years(employee_to_location_id, location_id, agency_id, year, pay_type, job_title_id,
                                     raw_dataset_table_id, raw_dataset_table_id_raw_id)
select distinct t1.employee_to_location_id,
                t1.agency_location_id,
                t1.agency_id,
                t1.year,
                'Salary',
                t1.job_title_id,
                1,
                t1.id
from tmp_mi_1nf__old t1
where t1.salary is not null;

update pess_employee_work_years
set md5_hash = null;

select CONCAT_WS(' ', employee_to_location_id, location_id, agency_id, year, full_or_part_status, pay_type, hourly_rate,
                 job_title_id, raw_dataset_table_id, raw_dataset_table_id_raw_id)
from pess_employee_work_years;

update pess_employee_work_years
set md5_hash = MD5(CONCAT_WS(' ', employee_to_location_id, location_id, agency_id, year, full_or_part_status, pay_type,
                             hourly_rate, job_title_id, raw_dataset_table_id, raw_dataset_table_id_raw_id));
#=======================================================================================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_compensations;
SET FOREIGN_KEY_CHECKS = 1;

select t1.employee_work_years_id, 3, t1.salary, 1
from tmp_mi_1nf__old t1
where t1.employee_work_years_id is not null;

insert into pess_compensations (employee_work_year_id, compensation_type_id, value, is_total_compensation)
select t1.employee_work_years_id, 3, t1.salary, 1
from tmp_mi_1nf__old t1
where t1.employee_work_years_id is not null;
#=======================================================================================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_address_employee_association_types;
TRUNCATE TABLE public_employees_salaries_staging.pess_addresses;
TRUNCATE TABLE public_employees_salaries_staging.pess_agencies;
TRUNCATE TABLE public_employees_salaries_staging.pess_agency_location_types;
TRUNCATE TABLE public_employees_salaries_staging.pess_agency_locations;
TRUNCATE TABLE public_employees_salaries_staging.pess_agency_types;
TRUNCATE TABLE public_employees_salaries_staging.pess_compensation_types;
TRUNCATE TABLE public_employees_salaries_staging.pess_compensations;
TRUNCATE TABLE public_employees_salaries_staging.pess_employee_work_years;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees_to_addresses;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees_to_locations;
TRUNCATE TABLE public_employees_salaries_staging.pess_job_titles;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_job_titles;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_agencies;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_agency_locations;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees_to_locations;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employee_work_years;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employee_work_years;
SET FOREIGN_KEY_CHECKS = 1;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_compensations;
SET FOREIGN_KEY_CHECKS = 1;

#=======================================================================================================================

update pess_agencies a1
    join (select t1.md5_agency from tmp_il_1nf t1 group by t1.md5_agency) t2
    on a1.raw_agency_md5_hash = t2.md5_agency
set a1.dataset_id = 3
where t2.md5_agency is not null;

update pess_agencies a1
    join (select t1.md5_agency from tmp_mi_1nf t1 group by t1.md5_agency) t2
    on a1.raw_agency_md5_hash = t2.md5_agency
set a1.dataset_id = 1
where t2.md5_agency is not null;

update pess_agencies a1
    join (select t1.md5_agency from tmp_fl_1nf t1 group by t1.md5_agency) t2
    on a1.raw_agency_md5_hash = t2.md5_agency
set a1.dataset_id = 4
where t2.md5_agency is not null;

update pess_agencies a1
    join (select t1.md5_agency from tmp_mi_1nf t1 group by t1.md5_agency) t2
    on a1.raw_agency_md5_hash = t2.md5_agency
set a1.dataset_id = 1
where t2.md5_agency is not null;