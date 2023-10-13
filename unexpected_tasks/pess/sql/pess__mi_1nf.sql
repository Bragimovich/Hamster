CREATE TABLE tmp_mi_1nf LIKE usa_raw.michigan_public_employee_salary;

alter table tmp_mi_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_mi_1nf;

INSERT INTO tmp_mi_1nf
SELECT *
FROM usa_raw.michigan_public_employee_salary;

select count(*)
from usa_raw.michigan_public_employee_salary
where deleted = 1;

#= employees ==========================================================================================================#

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees;
SET FOREIGN_KEY_CHECKS = 1;

update tmp_mi_1nf
set md5_employee = MD5(CONCAT_WS('', full_name, first_name, middle_name, last_name, data_source_url));

select full_name, employer, count(*)
from usa_raw.michigan_public_employee_salary
# where employer in ("corrections", "attorney general")
group by full_name, employer
order by employer;

insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix,
                                   data_source_url)
select distinct t1.md5_employee,
                if(m2.source_id is null, 0, 1)               as cleaned,
                if(m2.source_id is null, t1.full_name, null) as full_name,
                nullif(m2.name_first, ''),
                nullif(m2.name_middle, ''),
                nullif(m2.name_last, ''),
                nullif(m2.suffixes, ''),
                t1.data_source_url
from tmp_mi_1nf t1
         left join usa_raw.michigan_public_employee_salary__full_names m1
                   on t1.full_name = m1.full_name
         left join usa_raw.michigan_public_employee_salary__full_names_loki_namesplits m2
                   on m1.id = m2.source_id
where t1.full_name <> ',';

update tmp_mi_1nf
set employee_id = null;

update tmp_mi_1nf t1
    left join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;

select count(distinct t1.md5_employee)
from tmp_mi_1nf t1; # 243_625

update pess_employees e1
    join (select t1.md5_employee from tmp_mi_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
set e1.state      = 'MI',
    e1.dataset_id = 1;

#= job_titles =========================================================================================================#

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_job_titles;
SET FOREIGN_KEY_CHECKS = 1;

select job, count(*) as count
from usa_raw.michigan_public_employee_salary
group by job
order by count desc;

insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select j1.job                           as raw_job_title,
       if(m1.job_cleaned is null, 0, 1) as cleaned,
       m1.job_cleaned                   as job_title
from (select distinct job
      from tmp_mi_1nf
      where job is not null) j1
         left join usa_raw.michigan_puplic_employee_salary__jobs m1
                   on j1.job = m1.job;

update tmp_mi_1nf t1
    left join pess_job_titles j1
    on t1.job = j1.raw_job_title
set t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_agencies;
SET FOREIGN_KEY_CHECKS = 1;

insert ignore into pess_agencies (raw_agency_name, cleaned, agency_name, limpar_uuid)
select distinct t1.employer,
                if(m1.agency_clean is null, 0, 1) as cleaned,
                m1.agency_clean,
                m1.limpar_UUID
from tmp_mi_1nf t1
         left join usa_raw.michigan_public_employee_salary__agencies_cleaned_by_rylan m1
                   on t1.employer = m1.agency
where t1.employer is not null;

update tmp_mi_1nf t1
    left join pess_agencies a1
    on t1.employer = a1.raw_agency_name
set t1.agency_id = a1.id;

update tmp_mi_1nf t1
set t1.md5_agency = MD5(CONCAT_WS('+', employer, data_source_url))
where employer is not null;

#= agency_locations ===================================================================================================#

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_agency_locations;
SET FOREIGN_KEY_CHECKS = 1;

insert into pess_agency_locations (agency_id, address_id, office_type_id)
select distinct id, null, null
from pess_agencies;

update tmp_mi_1nf
set agency_location_id = null;

update tmp_mi_1nf t1
    join pess_agency_locations a1
    on t1.agency_id = a1.agency_id
set t1.agency_location_id = a1.id;

#= employees_to_locations =============================================================================================#

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_employees_to_locations;
SET FOREIGN_KEY_CHECKS = 1;

update pess_employees_to_locations
set md5_hash = null;

insert into pess_employees_to_locations (employee_id, location_id, isolated_known_date)
select distinct t1.employee_id, t1.agency_location_id, t1.year
from tmp_mi_1nf t1
where t1.employee_id is not null;

update pess_employees_to_locations
set md5_hash = MD5(CONCAT_WS('+', employee_id, location_id, ifnull(start_month, ''), ifnull(start_day_of_month, ''),
                             ifnull(start_year, ''), ifnull(end_month, ''), ifnull(end_day_of_month, ''), end_year,
                             isolated_known_date));

update tmp_mi_1nf
set employee_to_location_id = null;

update tmp_mi_1nf t1
    join pess_employees_to_locations e1
    on t1.employee_id = e1.employee_id and t1.agency_location_id = e1.location_id and
       t1.year = e1.isolated_known_date
set t1.employee_to_location_id = e1.id;

#= employee_work_years ================================================================================================#

select t1.employee_to_location_id, t1.agency_location_id, t1.agency_id, t1.year, t1.job, t1.id
from tmp_mi_1nf t1
where t1.employee_id is not null;

insert into pess_employee_work_years(employee_id, agency_id, year, pay_type, job_title_id,
                                     raw_dataset_table_id, raw_dataset_table_id_raw_id, data_source_url)
select distinct t1.employee_id,
                t1.agency_id,
                t1.year,
                'Wage',
                t1.job_title_id,
                1,
                t1.id,
                t1.data_source_url
from tmp_mi_1nf t1
where t1.employee_id is not null;

update pess_employee_work_years
set md5_hash = null;

select CONCAT_WS('+', employee_id, ifnull(employee_to_location_id, ''), ifnull(location_id, ''), agency_id, year,
                 ifnull(full_or_part_status, ''), ifnull(pay_type, ''), ifnull(hourly_rate, ''),
                 ifnull(job_title_id, ''), ifnull(raw_dataset_table_id, ''), ifnull(raw_dataset_table_id_raw_id, ''),
                 data_source_url)
from pess_employee_work_years;

update pess_employee_work_years
set md5_hash = MD5(CONCAT_WS('+', employee_id, ifnull(employee_to_location_id, ''), ifnull(location_id, ''), agency_id,
                             year, ifnull(full_or_part_status, ''), ifnull(pay_type, ''), ifnull(hourly_rate, ''),
                             ifnull(job_title_id, ''), ifnull(raw_dataset_table_id, ''),
                             ifnull(raw_dataset_table_id_raw_id, ''), data_source_url));

update tmp_mi_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, year, '', 'Wage', '', ifnull(job_title_id, ''), 1, id,
                            data_source_url))
where employee_id is not null;

update tmp_mi_1nf
set employee_work_year_id = null;

update tmp_mi_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.employee_work_year_id = e1.id;

#= compensations ======================================================================================================#

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE public_employees_salaries_staging.pess_compensations;
SET FOREIGN_KEY_CHECKS = 1;

update tmp_mi_1nf
set compensation_id = null;

update tmp_mi_1nf
set md5_comp = null;

update tmp_mi_1nf
set md5_comp = MD5(CONCAT_WS('+', employee_work_year_id, 1, salary, '', 1, ''))
where employee_id is not null;

insert into pess_compensations (md5_hash)
select distinct t1.md5_comp
from tmp_mi_1nf t1
where t1.md5_comp is not null;

update tmp_mi_1nf t1
    join pess_compensations c1 on
        t1.md5_comp = c1.md5_hash
set t1.compensation_id = c1.id;

explain
update pess_compensations c1
    join tmp_mi_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.employee_work_year_id = t1.employee_work_year_id,
    c1.compensation_type_id  = 1,
    c1.value                 = t1.salary,
    c1.is_total_compensation = 1;

update pess_compensations c1
    join tmp_mi_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.data_source_url = t1.data_source_url;

#======================================================================================================================#
