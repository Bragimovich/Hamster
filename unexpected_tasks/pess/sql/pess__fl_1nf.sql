#= create =============================================================================================================#

CREATE TABLE tmp_fl_1nf LIKE usa_raw.fl_public_employee_salaries;

alter table tmp_fl_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_fl_1nf;

INSERT INTO tmp_fl_1nf
SELECT *
FROM usa_raw.fl_public_employee_salaries;

alter table tmp_fl_1nf
    drop column created_at,
    drop column updated_at,
    drop column scrape_dev_name,
    drop column scrape_frequency,
    drop column file_name,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column expected_scrape_frequency,
    drop column dataset_name_prefix,
    drop column scrape_status,
    drop column pl_gather_task_id,
    drop column md5_hash,
    drop column run_id;

#= employees ==========================================================================================================#

update tmp_fl_1nf
set md5_employee = MD5(CONCAT_WS(' ', first_name, ifnull(middle_name, ''), last_name, data_source_url));

select count(*)
from tmp_fl_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;

insert ignore into pess_employees (raw_employee_md5_hash)
select distinct t1.md5_employee
from tmp_fl_1nf t1;

update tmp_fl_1nf
set employee_id = null;

update tmp_fl_1nf t1
    left join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;

select count(distinct t1.md5_employee)
from tmp_fl_1nf t1;

select e1.raw_employee_md5_hash, 1, f2.full_name_cleaned, f2.first_name, f2.middle_name, f2.last_name
from pess_employees e1
         join (select id, t1.md5_employee from tmp_fl_1nf t1 group by t1.md5_employee) t2
              on e1.raw_employee_md5_hash = t2.md5_employee
         join usa_raw.fl_public_employee_salaries_cleaned f1 on t2.id = f1.raw_id
         join usa_raw.fl_public_employee_salaries_names_unique f2 on f1.name_id = f2.id
group by f2.id
having count(*) > 1;

update pess_employees e1
    join (select t1.id, t1.md5_employee, t1.data_source_url from tmp_fl_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
    join usa_raw.fl_public_employee_salaries_cleaned f1 on t2.id = f1.raw_id
    join usa_raw.fl_public_employee_salaries_names_unique f2 on f1.name_id = f2.id
set e1.cleaned         = 1,
    e1.full_name       = f2.full_name_cleaned,
    e1.first_name      = f2.first_name,
    e1.middle_name     = nullif(f2.middle_name, ''),
    e1.last_name       = f2.last_name,
    e1.data_source_url = t2.data_source_url;

update pess_employees e1
    join (select t1.md5_employee from tmp_fl_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
set e1.state      = 'FL',
    e1.dataset_id = 4;

#= job_titles =========================================================================================================#

select class_title, count(*) as count
from usa_raw.fl_public_employee_salaries
group by class_title
order by count desc;

insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select j1.class_title                           as raw_job_title,
       if(f2.class_title_cleaned is null, 0, 1) as cleaned,
       f2.class_title_cleaned                   as job_title
from (select id, class_title
      from tmp_fl_1nf
      group by class_title
      having class_title is not null) j1
         join usa_raw.fl_public_employee_salaries_cleaned f1
              on j1.id = f1.raw_id
         join usa_raw.fl_public_employee_salaries_class_titles_unique f2
              on f1.class_title_id = f2.id;

update tmp_fl_1nf t1
    left join pess_job_titles j1
    on t1.class_title = j1.raw_job_title
set t1.job_title_id = j1.id;

#= agencies ===========================================================================================================#

select distinct t.agency_id
from tmp_fl_1nf t
where t.agency_id < 747;

update tmp_fl_1nf t1
set t1.md5_agency = MD5(CONCAT_WS('+', agency, data_source_url))
where t1.agency is not null;

select count(distinct t1.agency) common_agencies
from tmp_fl_1nf t1
         join pess_agencies a1
              on t1.agency = a1.raw_agency_name
where a1.raw_agency_md5_hash is not null;

select agency, count(*) as count
from usa_raw.fl_public_employee_salaries
group by agency
order by count desc;

insert ignore into pess_agencies (raw_agency_name, cleaned, agency_name)
select t1.agency                                 as raw_job_title,
       if(f2.agency_name_cleaned2 is null, 0, 1) as cleaned,
       f2.agency_name_cleaned2                   as job_title
from (select id, agency
      from tmp_fl_1nf
      group by agency
      having agency is not null) t1
         join usa_raw.fl_public_employee_salaries_cleaned f1
              on t1.id = f1.raw_id
         join usa_raw.fl_public_employee_salaries_agencies_unique f2
              on f1.agency_id = f2.id;

update tmp_fl_1nf t1
    left join pess_agencies a1
    on t1.agency = a1.raw_agency_name
set t1.agency_id = a1.id;

#= agency_locations ===================================================================================================#

# insert into agency_locations (agency_id, address_id, office_type_id)
# select distinct id, null, null
# from agencies;
#
# update tmp_fl_1nf
# set agency_location_id = null;
#
# update tmp_fl_1nf t1
#     join agency_locations a1
#     on t1.agency_id = a1.agency_id
# set t1.agency_location_id = a1.id;

#= employees_to_locations =============================================================================================#

# update employees_to_locations
# set md5_hash = null;
#
# insert into employees_to_locations (employee_id, location_id, isolated_known_date)
# select distinct t1.employee_id, t1.agency_location_id, t1.year
# from tmp_fl_1nf t1
# where t1.employee_id is not null;
#
# update employees_to_locations
# set md5_hash = MD5(CONCAT_WS('+', employee_id, location_id, ifnull(start_month, ''), ifnull(start_day_of_month, ''),
#                              ifnull(start_year, ''), ifnull(end_month, ''), ifnull(end_day_of_month, ''), end_year,
#                              isolated_known_date));
#
# update tmp_fl_1nf
# set employee_to_location_id = null;
#
# update tmp_fl_1nf t1
#     join employees_to_locations e1
#     on t1.employee_id = e1.employee_id and t1.agency_location_id = e1.location_id and
#        t1.year = e1.isolated_known_date
# set t1.employee_to_location_id = e1.id;

#= employee_work_years ================================================================================================#

update tmp_fl_1nf
set full_or_part_time_cleaned = if(full_or_part_time like 'full%', 'full-time',
                                   if(full_or_part_time like 'part%', 'part-time', ''));

update tmp_fl_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, full_or_part_time_cleaned, 'Salary', '',
                            ifnull(job_title_id, ''), 4, id, data_source_url))
where annual_salary is not null;

update tmp_fl_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, full_or_part_time_cleaned, 'Hourly', '',
                            ifnull(job_title_id, ''), 4, id, data_source_url))
where employee_type = 'OPS';

insert into pess_employee_work_years (md5_hash)
select distinct t1.md5_ewy
from tmp_fl_1nf t1
where t1.md5_ewy is not null;

insert into pess_employee_work_years (md5_hash)
select distinct t1.md5_ewy
from tmp_fl_1nf t1
where t1.employee_type = 'OPS';

update tmp_fl_1nf
set ewy_id = null;

explain
update tmp_fl_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;

update tmp_fl_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id
where t1.employee_type = 'OPS';

explain
update pess_employee_work_years e1
    join tmp_fl_1nf t1
    on e1.md5_hash = t1.md5_ewy
set e1.employee_id                 = t1.employee_id,
    e1.agency_id                   = t1.agency_id,
    e1.year                        = t1.year,
    e1.full_or_part_status         = t1.full_or_part_time_cleaned,
    e1.pay_type                    = 'Salary',
    e1.job_title_id                = t1.job_title_id,
    e1.raw_dataset_table_id        = 4,
    e1.raw_dataset_table_id_raw_id = t1.id,
    e1.data_source_url             = t1.data_source_url;

explain
update pess_employee_work_years e1
    join tmp_fl_1nf t1
    on e1.md5_hash = t1.md5_ewy
set e1.employee_id                 = t1.employee_id,
    e1.agency_id                   = t1.agency_id,
    e1.year                        = t1.year,
    e1.full_or_part_status         = t1.full_or_part_time_cleaned,
    e1.pay_type                    = 'Hourly',
    e1.job_title_id                = t1.job_title_id,
    e1.raw_dataset_table_id        = 4,
    e1.raw_dataset_table_id_raw_id = t1.id,
    e1.data_source_url             = t1.data_source_url
where t1.employee_type = 'OPS';

update pess_employee_work_years e1
    join tmp_fl_1nf t1
    on e1.md5_hash = t1.md5_ewy
set e1.hourly_rate = t1.ops_hourly_rate
where t1.employee_type = 'OPS'; # 36_721

explain
update pess_employee_work_years e1
    join tmp_fl_1nf t1
    on e1.id = t1.ewy_id
set e1.md5_hash = t1.md5_ewy
where t1.employee_type = 'OPS';

#= compensations ======================================================================================================#

update tmp_fl_1nf
set comp_id = null;

update tmp_fl_1nf
set md5_comp = null;

update tmp_fl_1nf
set md5_comp = MD5(CONCAT_WS('+', ewy_id, 2, annual_salary, '', 1, ''))
where annual_salary is not null;

insert into pess_compensations (md5_hash)
select distinct t1.md5_comp
from tmp_fl_1nf t1
where t1.md5_comp is not null;

update tmp_fl_1nf t1
    join pess_compensations c1 on
        t1.md5_comp = c1.md5_hash
set t1.comp_id = c1.id;

explain
update pess_compensations c1
    join tmp_fl_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.employee_work_year_id = t1.ewy_id,
    c1.compensation_type_id  = 2,
    c1.value                 = t1.annual_salary,
    c1.is_total_compensation = 1;

update pess_compensations c1
    join tmp_fl_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.data_source_url = t1.data_source_url;

update tmp_fl_1nf t1
set t1.md5_comp = MD5(CONCAT_WS('+', t1.ewy_id, '', '', '', '', '', 4, t1.data_source_url))
where t1.employee_type = 'OPS';

insert into pess_compensations (md5_hash)
select distinct t1.md5_comp
from tmp_fl_1nf t1
where t1.md5_comp is not null
  and t1.employee_type = 'OPS';

update tmp_fl_1nf t1
    join pess_compensations c1 on
        t1.md5_comp = c1.md5_hash
set t1.comp_id = c1.id
where employee_type = 'OPS';

update pess_compensations c1
    join tmp_fl_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.employee_work_year_id = t1.ewy_id,
    c1.dataset_id            = 4,
    c1.data_source_url       = t1.data_source_url
where employee_type = 'OPS';

#======================================================================================================================#

select full_or_part_time,
       'OPS'                                                                                                  as `OPS employee`,
       if(full_or_part_time like 'full%', 'full-time', if(full_or_part_time like 'part%', 'part-time', null)) as status,
       count(*)
from tmp_fl_1nf
where employee_type = 'OPS'
group by full_or_part_time;

select count(distinct t.md5_employee)
from tmp_fl_1nf t; # 148_200

select count(distinct t.md5_employee)
from tmp_fl_1nf t
where employee_type = 'OPS'; # distinct - 21_568, all - 36_721

select count(distinct t.md5_comp)
from tmp_fl_1nf t
where employee_type = 'OPS'; # 0

select count(*)
from pess_compensations c1
         join tmp_fl_1nf t1
              on c1.md5_hash = t1.md5_comp
where c1.dataset_id is null;

select count(*) from usa_raw.nv_public_employee_salary;