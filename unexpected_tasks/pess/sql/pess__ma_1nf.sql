#= create ==============================================================================================================

CREATE TABLE tmp_ma_1nf LIKE usa_raw.ma_public_employee_salaries;

alter table tmp_ma_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_ma_1nf;

alter table tmp_ma_1nf
    modify md5_hash varchar(255) default null;

alter table tmp_ma_1nf
    drop column contract,
    drop column bargaining_group_no,
    drop column bargaining_group_title,
    drop column dept_code,
    drop column created_at,
    drop column updated_at,
    drop column scrape_frequency,
    drop column file_name,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column expected_scrape_frequency,
    drop column dataset_name_prefix,
    drop column scrape_status,
    drop column pl_gather_task_id,
    drop column run_id,
    drop column created_by;

alter table tmp_ma_1nf
    add column `md5_employee`     varchar(255) null after id,
    add column `employee_id`      bigint       null after md5_employee,
    add column `job_title_id`     bigint       null after employee_id,
    add column `md5_agency`       varchar(255) null after job_title_id,
    add column `agency_id`        bigint       null after md5_agency,
    add column `md5_ewy`          varchar(255) null after agency_id,
    add column `ewy_id`           bigint       null after md5_ewy,
    add column `md5_gross_wages`  varchar(255) null after ewy_id,
    add column `md5_overtime_pay` varchar(255) null after md5_gross_wages,
    add index `md5_employee` (`md5_employee`),
    add index `md5_agency` (`md5_agency`),
    add index `md5_ewy` (`md5_ewy`);

insert into tmp_ma_1nf (id, trans_no, `year`, last_name, first_name, department_division, position_title, position_type,
                        service_end_date, pay_total_actual, pay_base_actual, pay_buyout_actual, pay_overtime_actual,
                        pay_other_actual, annual_rate, pay_year_to_date, department_location_zip_code, data_source_url)
select m1.id,
       m1.tans_no,
       m1.`year`,
       m1.last_name,
       m1.first_name,
       m1.department_division,
       m1.position_title,
       m1.position_type,
       m1.service_end_date,
       m1.pay_total_actual,
       m1.pay_base_actual,
       m1.pay_buyout_actual,
       m1.pay_overtime_actual,
       m1.pay_other_actual,
       m1.annual_rate,
       m1.pay_year_to_date,
       m1.department_location_zip_code,
       m1.data_source_url
from usa_raw.ma_public_employee_salaries m1
where m1.department_division not regexp 'college|universit|academ';

#= initial data ========================================================================================================

explain usa_raw.ma_public_employee_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'ma_public_employee_salaries%', 'Massachusetts Public Employee Salary', 'Scrape',
        'https://cthru.data.socrata.com/dataset/Commonwealth-Of-Massachusetts-Payrollv2/rxhc-k6iz', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('ma_public_employee_salaries', 7, 'Alim L.');

insert ignore into pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
values ('Pay Total Actual', 0, 'Pay Total Actual', 'Alim L.'),
       ('Pay Base Actual', 0, 'Pay Base Actual', 'Alim L.'),
       ('Pay Buyout Actual', 0, 'Pay Buyout Actual', 'Alim L.'),
       ('Pay Overtime Actual', 0, 'Pay Overtime Actual', 'Alim L.'),
       ('Pay Other Actual', 0, 'Pay Other Actual', 'Alim L.'),
       ('Annual Rate', 0, 'Annual Rate', 'Alim L.'),
       ('Pay Year to Date', 0, 'Pay Year to Date', 'Alim L.');

update tmp_ma_1nf t1
    join usa_raw.ma_public_employee_salaries m1
    on t1.id = m1.id
set t1.md5_hash = MD5(CONCAT_WS('+', m1.`year`, m1.last_name, m1.first_name, m1.department_division, m1.position_title,
                                m1.position_type, m1.service_end_date, m1.pay_total_actual, m1.pay_base_actual,
                                m1.pay_buyout_actual, m1.pay_overtime_actual, m1.pay_other_actual, m1.annual_rate,
                                m1.pay_year_to_date, m1.department_location_zip_code, m1.contract,
                                m1.bargaining_group_no, m1.bargaining_group_title, m1.tans_no, m1.dept_code));

delete t1
from tmp_ma_1nf as t1
         left join state_salaries__raw.ma_payroll_csv as m1 on t1.md5_hash = m1.md5_hash
where m1.md5_hash is null;

update tmp_ma_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', t1.first_name, '', t1.last_name, t1.trans_no, t1.data_source_url)); # 1_196_728

update tmp_ma_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', t1.department_division, data_source_url));
# 1_196_728

#= employees ==========================================================================================================#

-- checks
select distinct year
from tmp_ma_1nf;

select count(*)
from tmp_ma_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash; # 0

select count(distinct t1.md5_employee) as total_employee
from tmp_ma_1nf t1; # 163_399 (177_348)

select count(distinct t1.trans_no) as total_employee
from tmp_ma_1nf t1; # 168_639

select t1.trans_no as num, t1.md5_employee as md5, count(distinct t1.md5_employee) as c
from tmp_ma_1nf t1
group by t1.trans_no
having c > 1
order by c desc;

update tmp_ma_1nf
set employee_id = null;

-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, first_name, middle_name, last_name, state,
                                   dataset_id, data_source_url)
select t1.md5_employee,
       1,
       t1.first_name,
       '',
       t1.last_name,
       'MA',
       7,
       t1.data_source_url
from tmp_ma_1nf t1
group by t1.md5_employee; # 177_348

update tmp_ma_1nf t1
    left join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 1_196_728

#= job_titles =========================================================================================================#

-- checks
select position_title, count(*) as count
from tmp_ma_1nf
group by position_title
order by position_title asc;
# 19_496
# order by count desc;

select distinct position_title
from tmp_ma_1nf
where position_title is not null; # 19_495

select count(distinct t1.position_title)
# select distinct t1.job_title
from tmp_ma_1nf t1
         join pess_job_titles j1
              on t1.position_title = j1.raw_job_title;
# 1_143

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.position_title, (m1.position_title_clean <> ''), m1.position_title_clean
from tmp_ma_1nf t1
         left join usa_raw.ma_public_employee_salaries__position_title m1
                   on t1.position_title = m1.position_title
where t1.position_title is not null
group by t1.position_title; # 18_352 = 19_495 - 1_143

update tmp_ma_1nf t1
    left join pess_job_titles j1
    on t1.position_title = j1.raw_job_title
set t1.job_title_id = j1.id;
# 1_196_728

#= agencies ===========================================================================================================#

-- checks
select department_division as agency
from usa_raw.ma_public_employee_salaries
where department_division regexp 'college|universit|academ'
group by agency
order by agency asc;

select count(distinct tmp_ma_1nf.md5_agency)
from tmp_ma_1nf;
#148

select distinct department_division
from tmp_ma_1nf;

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, pl_org_id, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.department_division,
       (m1.DEPARTMENT_DIVISION_CLEAN is not null),
       m1.DEPARTMENT_DIVISION_CLEAN,
       m1.pl_production_org_id,
       7,
       t1.data_source_url
from tmp_ma_1nf t1
         left join usa_raw.ma_public_employee_salaries_department_division_clean m1
                   on t1.department_division = m1.DEPARTMENT_DIVISION
group by t1.md5_agency; #148

update tmp_ma_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 1_196_728

#= addresses ==========================================================================================================#

-- checks
select CONCAT_WS('+', ifnull(m1.ADDRESS, ''), '', ifnull(m1.CITY, ''), '', 'MA', ifnull(m1.ZIP, ''))      as con_cat,
       MD5(CONCAT_WS('+', ifnull(m1.ADDRESS, ''), '', ifnull(m1.CITY, ''), '', 'MA', ifnull(m1.ZIP, ''))) as md5_address
from tmp_ma_1nf as t1
         join usa_raw.ma_public_employee_salaries_department_division_clean as m1
              on t1.department_division = m1.DEPARTMENT_DIVISION
where m1.pl_production_org_id is not null
group by t1.department_division;

select distinct t1.md5_address
from tmp_ma_1nf t1
where t1.md5_address is not null;

-- process
update tmp_ma_1nf t1
    join usa_raw.ma_public_employee_salaries_department_division_clean as m1
    on t1.department_division = m1.DEPARTMENT_DIVISION
set t1.md5_address = MD5(CONCAT_WS('+', ifnull(m1.ADDRESS, ''), '', ifnull(m1.CITY, ''), '', 'MA', ifnull(m1.ZIP, '')))
where m1.pl_production_org_id is not null; # 1_181_204

insert into pess_addresses (raw_address_md5_hash, street_address, city, state, zip)
select t1.md5_address, m1.ADDRESS, m1.CITY, 'MA', m1.ZIP
from tmp_ma_1nf t1
         join usa_raw.ma_public_employee_salaries_department_division_clean as m1
              on t1.department_division = m1.DEPARTMENT_DIVISION
where t1.md5_address is not null
group by t1.md5_address; # 125

update tmp_ma_1nf t1
    join pess_addresses a1 on
            t1.md5_address = a1.raw_address_md5_hash
set t1.address_id = a1.id;

#= agency_locations ===================================================================================================#

-- checks
select distinct t1.address_id, t1.agency_id
from tmp_ma_1nf t1
where t1.address_id is not null;

select group_concat(distinct t1.department_division) as agencies,
       group_concat(distinct t1.address_id)          as address_ids,
       group_concat(distinct t1.agency_id)           as agency_ids
from tmp_ma_1nf t1
where t1.address_id is not null
group by t1.address_id;
#127

-- process
insert into pess_agency_locations (address_id, agency_id, data_source_url)
select distinct t1.address_id, t1.agency_id, t1.data_source_url
from tmp_ma_1nf t1
where t1.address_id is not null;

update tmp_ma_1nf t1
    join pess_agency_locations a1
    on t1.address_id = a1.address_id and t1.agency_id = a1.agency_id
set t1.al_id = a1.id;

#= employees_to_locations =============================================================================================#

-- checks
select `year`, service_end_date
from tmp_ma_1nf
where tmp_ma_1nf.md5_employee = '806ea99b5e2fdcd8c0fd96021340e7d8';

-- process
insert into pess_employees_to_locations (employee_id, location_id, isolated_known_date, data_source_url)
select distinct t1.employee_id, t1.al_id, t1.year, t1.data_source_url
from tmp_ma_1nf t1
where t1.al_id is not null; # 1_084_913

update tmp_ma_1nf t1
    join pess_employees_to_locations e1
    on t1.employee_id = e1.employee_id and t1.al_id = e1.location_id and t1.year = e1.isolated_known_date
set t1.etl_id = e1.id;
# 1_181_204

#= employee_work_years ================================================================================================#

-- checks
select distinct position_type
from tmp_ma_1nf;

select position_type, full_or_part_time_cleaned
from tmp_ma_1nf
group by position_type;

update tmp_ma_1nf
set full_or_part_time_cleaned = if(position_type like 'full%', 'full-time',
                                   if(position_type like 'part%', 'part-time', ''))
where position_type <> 'N/A';

update tmp_ma_1nf
set ewy_id = null;

-- process
update tmp_ma_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, ifnull(etl_id, ''), ifnull(al_id, ''), agency_id, `year`,
                            ifnull(full_or_part_time_cleaned, ''), 'Salary', '', ifnull(job_title_id, ''), 7, id,
                            data_source_url));

insert ignore into pess_employee_work_years(md5_hash, employee_id, employee_to_location_id, location_id, agency_id,
                                            `year`,
                                            full_or_part_status, pay_type, job_title_id, raw_dataset_table_id,
                                            raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.etl_id,
       t1.al_id,
       t1.agency_id,
       t1.year,
       t1.full_or_part_time_cleaned,
       'Salary',
       t1.job_title_id,
       7,
       t1.id,
       t1.data_source_url
from tmp_ma_1nf t1
group by t1.md5_ewy; # 1_196_728

update tmp_ma_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 1_196_728

#= compensations ======================================================================================================#

-- pay_total_actual
update tmp_ma_1nf t1
set t1.md5_pay_total_actual = MD5(CONCAT_WS('+', t1.ewy_id, 12, t1.pay_total_actual, '', 1, '', 7, t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_pay_total_actual, t1.ewy_id, 12, t1.pay_total_actual, 1, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

-- pay_base_actual
update tmp_ma_1nf t1
set t1.md5_pay_base_actual = MD5(CONCAT_WS('+', t1.ewy_id, 13, t1.pay_base_actual, '', 0, '', 7, t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_pay_base_actual, t1.ewy_id, 13, t1.pay_base_actual, 0, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

-- pay_buyout_actual
update tmp_ma_1nf t1
set t1.md5_pay_buyout_actual = MD5(CONCAT_WS('+', t1.ewy_id, 14, t1.pay_buyout_actual, '', 0, '', 7,
                                             t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_pay_buyout_actual, t1.ewy_id, 14, t1.pay_buyout_actual, 0, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

-- pay_overtime_actual
update tmp_ma_1nf t1
set t1.md5_pay_overtime_actual = MD5(CONCAT_WS('+', t1.ewy_id, 15, t1.pay_overtime_actual, '', 0, '', 7,
                                               t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_pay_overtime_actual, t1.ewy_id, 15, t1.pay_overtime_actual, 0, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

-- pay_other_actual
update tmp_ma_1nf t1
set t1.md5_pay_other_actual = MD5(CONCAT_WS('+', t1.ewy_id, 16, t1.pay_other_actual, '', 0, '', 7, t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_pay_other_actual, t1.ewy_id, 16, t1.pay_other_actual, 0, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

-- annual_rate
update tmp_ma_1nf t1
set t1.md5_annual_rate = MD5(CONCAT_WS('+', t1.ewy_id, 17, t1.annual_rate, '', 0, '', 7, t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_annual_rate, t1.ewy_id, 17, t1.annual_rate, 0, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

-- pay_year_to_date
update tmp_ma_1nf t1
set t1.md5_pay_year_to_date = MD5(CONCAT_WS('+', t1.ewy_id, 18, t1.pay_year_to_date, '', 0, '', 7, t1.data_source_url));
# 1_196_728

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_pay_year_to_date, t1.ewy_id, 18, t1.pay_year_to_date, 0, 7, t1.data_source_url
from tmp_ma_1nf t1;
# 1_196_728

#= ma_payroll_csv ======================================================================================================

alter table state_salaries__raw.ma_payroll_csv
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

update state_salaries__raw.ma_payroll_csv m1
set m1.service_end_date = str_to_date(m1.service_end_date, '%m/%d/%Y');

update state_salaries__raw.ma_payroll_csv m1
set m1.md5_hash = MD5(CONCAT_WS('+', m1.`year`, m1.name_last, m1.name_first, m1.department_division, m1.position_title,
                                m1.position_type, m1.service_end_date, m1.pay_total_actual, m1.pay_base_actual,
                                m1.pay_buyout_actual, m1.pay_overtime_actual, m1.pay_other_actual, m1.annual_rate,
                                m1.pay_year_to_date, m1.department_location_zip_code, m1.contract,
                                m1.bargaining_group_no, m1.bargaining_group_title, m1.trans_no, m1.dept_code));

show table status like 'ma_public_employee_salaries';

select *
from usa_raw.ma_public_employee_salaries
where `year` = 2010
  and last_name = 'abdallah'
  and first_name = 'joanne'
order by position_title asc;

select *
from state_salaries__raw.ma_payroll_csv
where `year` = 2010
  and name_last = 'abdallah'
  and name_first = 'joanne'
order by position_title asc;

select md5(concat_ws('', `file_name`, `year`, `last_name`, `first_name`, `department_division`, `position_title`,
                     `position_type`, `service_end_date`, `pay_total_actual`, `pay_base_actual`, `pay_buyout_actual`,
                     `pay_overtime_actual`, `pay_other_actual`, `annual_rate`, `pay_year_to_date`,
                     `department_location_zip_code`, `contract`, `bargaining_group_no`, `bargaining_group_title`,
                     `tans_no`, `dept_code`, `data_source_url`))
from usa_raw.ma_public_employee_salaries;

select *, count(md5_hash) as count
from tmp_ma_1nf
group by md5_hash
having count > 1;

select count(*) as count
from tmp_ma_1nf as t1
         join state_salaries__raw.ma_payroll_csv as m1 on t1.md5_hash = m1.md5_hash; # 1_196_728

select count(*)
from state_salaries__raw.ma_payroll_csv m1
where m1.department_division not like '%college%'
  and m1.department_division not like '%universit%'
  and m1.department_division not like '%academ%'; # 1_196_728

