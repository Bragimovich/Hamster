#= checks =============================================================================================================#

select distinct master_department_agency_desc, paid_department_agency_desc
from usa_raw.nj_state_employees_salaries;

select distinct p1.paid_department_agency_desc
from (select distinct paid_department_agency_desc from usa_raw.nj_state_employees_salaries) as p1
         left join (select distinct master_department_agency_desc from usa_raw.nj_state_employees_salaries) as p2
                   on p1.paid_department_agency_desc = p2.master_department_agency_desc
where p2.master_department_agency_desc is null;

select distinct p1.paid_department_agency_desc
from (select distinct paid_department_agency_desc from usa_raw.nj_state_employees_salaries) as p1
         left join (select distinct master_department_agency_desc from usa_raw.nj_state_employees_salaries) as p2
                   on p1.paid_department_agency_desc = p2.master_department_agency_desc
where p2.master_department_agency_desc is null;

select distinct paid_department_agency_desc, master_department_agency_desc
from usa_raw.nj_state_employees_salaries
where paid_department_agency_desc <> master_department_agency_desc
  and paid_department_agency_desc is not null
  and record_type = 'DETAIL';

select distinct compensation_method
from usa_raw.nj_state_employees_salaries;

select payroll_id, calendar_year, count(*) as total
from usa_raw.nj_state_employees_salaries
where record_type = 'MASTER'
group by payroll_id, calendar_year
having total > 1
order by total desc;

select n1.*
from usa_raw.nj_state_employees_salaries as n1
         join (select payroll_id, calendar_year, count(*) as total
               from usa_raw.nj_state_employees_salaries
               where record_type = 'MASTER'
               group by payroll_id, calendar_year
               having total > 1) as dup
where n1.calendar_year = dup.calendar_year
  and n1.payroll_id = dup.payroll_id
  and n1.record_type = 'MASTER'
order by n1.payroll_id;

select distinct data_source_url
from usa_raw.nj_state_employees_salaries; # single

select master_department_agency_desc as agency
from usa_raw.nj_state_employees_salaries
where master_department_agency_desc regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 1 - include it

select distinct calendar_year
from usa_raw.nj_state_employees_salaries;
# 2010-2022

select n1.*
from tmp_nj_1nf as n1
         join (select payroll_id, calendar_year, count(*) as total
               from tmp_nj_1nf
               group by payroll_id, calendar_year
               having total > 1) as dup
where n1.calendar_year = dup.calendar_year
  and n1.payroll_id = dup.payroll_id
order by n1.payroll_id;

delete;
select *
from tmp_nj_1nf
where id not in (select *
                 from (select max(id) as `id`
                       from tmp_nj_1nf
                       group by payroll_id, calendar_year) as dup)
order by id asc;

select group_concat(id) as `id`
from tmp_nj_1nf
group by payroll_id, calendar_year
order by id asc;

select t1.id
from tmp_nj_1nf t1,
     tmp_nj_1nf t2
where t1.id < t2.id
  and t1.calendar_year = t2.calendar_year
  and t1.payroll_id = t2.payroll_id;

#[x] create & fill =====================================================================================================

drop table tmp_nj_1nf;

truncate tmp_nj_1nf;

CREATE TABLE tmp_nj_1nf LIKE usa_raw.nj_state_employees_salaries;

alter table tmp_nj_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

alter table tmp_nj_1nf
    modify md5_hash varchar(100) default null;

alter table tmp_nj_1nf
    drop column ytd_earnings,
    drop column cash_in_lieu_maintenance,
    drop column lump_sum_pay,
    drop column retroactive_pay,
    drop column clothing_uniform_payments,
    drop column overtime_payments,
    drop column legislator_or_back_pay,
    drop column one_time_payments,
    drop column supplemental_pay,
    drop column regular_pay,
    drop column paid_section_desc,
    drop column paid_department_agency_desc,
    drop column employee_relations_group,
    drop column master_section_desc,
    drop column run_id,
    drop column scrape_frequency,
    drop column scrape_dev_name,
    drop column created_at,
    drop column updated_at,
    drop column md5_hash;

alter table tmp_nj_1nf
    add column `md5_employee`               varchar(255) null after id,
    add column `employee_id`                bigint       null after md5_employee,
    add column `job_title_id`               bigint       null after employee_id,
    add column `md5_agency`                 varchar(255) null after job_title_id,
    add column `agency_id`                  bigint       null after md5_agency,
    add column `md5_ewy`                    varchar(255) null after agency_id,
    add column `ewy_id`                     bigint       null after md5_ewy,
    add column `md5_ytd_regular_pay`        varchar(255) null after ewy_id,
    add column `md5_ytd_overtime_payments`  varchar(255) null after md5_ytd_regular_pay,
    add column `md5_ytd_all_other_payments` varchar(255) null after md5_ytd_overtime_payments,
    add column `md5_ytd_earnings`           varchar(255) null after md5_ytd_all_other_payments,
    add index `md5_employee` (`md5_employee`),
    add index `md5_agency` (`md5_agency`),
    add index `md5_ewy` (`md5_ewy`);

insert into tmp_nj_1nf (id, record_type, master_ytd_earnings, master_ytd_all_other_payments,
                        master_ytd_overtime_payments, master_ytd_regular_pay, compensation_method, master_title_desc,
                        master_department_agency_desc, salary_hourly_rate, original_employment_dte, full_name,
                        middle_initial, first_name, last_name, payroll_id, as_of_date, calendar_quarter, calendar_year,
                        data_source_url)
select id,
       record_type,
       master_ytd_earnings,
       master_ytd_all_other_payments,
       master_ytd_overtime_payments,
       master_ytd_regular_pay,
       compensation_method,
       master_title_desc,
       master_department_agency_desc,
       salary_hourly_rate,
       original_employment_dte,
       full_name,
       middle_initial,
       first_name,
       last_name,
       payroll_id,
       as_of_date,
       calendar_quarter,
       calendar_year,
       data_source_url
from usa_raw.nj_state_employees_salaries
where record_type = 'MASTER';
# 1_157_486

delete t1
from tmp_nj_1nf t1,
     tmp_nj_1nf t2
where t1.id < t2.id
  and t1.calendar_year = t2.calendar_year
  and t1.payroll_id = t2.payroll_id;
# 93_483
# 1_064_003

#[x] initial data =====================================================================================================

explain usa_raw.nj_state_employees_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'nj_state_employees_salaries%', 'State of New Jersey NJOIT Open Data Center', 'Scrape',
        'https://data.nj.gov/Government-Finance/YourMoney-Agency-Payroll/iqwc-r2w7/data', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('nj_state_employees_salaries', 2, 'Alim L.');

update tmp_nj_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', lower(trim(t1.full_name)), lower(trim(t1.payroll_id)),
                                    t1.data_source_url)); # 1_064_003

update tmp_nj_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.master_department_agency_desc)), t1.data_source_url));
# 1_064_003

INSERT INTO pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
VALUES ('YTD REGULAR PAY', 0, 'YTD REGULAR PAY', 'Alim L.'),
       ('YTD OVERTIME PAYMENTS', 0, 'YTD OVERTIME PAYMENTS', 'Alim L.'),
       ('YTD ALL OTHER PAYMENTS', 0, 'YTD ALL OTHER PAYMENTS', 'Alim L.'),
       ('YTD EARNINGS', 0, 'YTD EARNINGS', 'Alim L.');

#[x] employees =========================================================================================================

-- checks
select distinct full_name
from tmp_nj_1nf; # 171_493 - full_names

select count(*)
from tmp_nj_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;
# 0

-- full_name+payroll_id = 174_413
select count(distinct t1.md5_employee) as total_employee
from tmp_nj_1nf t1;

select full_name
from tmp_nj_1nf
where length(full_name) <> length(trim(full_name));

-- duplicates on full_name+agency+job_title
select md5_employee, full_name, master_department_agency_desc, group_concat(master_title_desc), count(*) as total
from tmp_nj_1nf
group by md5_employee, calendar_year
having total > 1
order by total desc; # 0

select full_name,
       group_concat(distinct master_department_agency_desc),
       calendar_year,
       group_concat(master_title_desc),
       group_concat(master_ytd_regular_pay),
       count(*) as count
from tmp_nj_1nf
group by full_name, master_department_agency_desc, calendar_year
having count > 1
order by count desc;

select sum(count)
from (select count(*) as count
      from tmp_nj_1nf
      group by md5_employee, calendar_year
      having count > 1
      order by count desc) as tmp;

update tmp_nj_1nf
set employee_id = null;

select count(*)
from tmp_nj_1nf as t1
         left join usa_raw.nj_state_employees_salaries__names_clean as n1 on t1.full_name = n1.full_name
where n1.full_name is null;


-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, state, dataset_id, data_source_url)
select t1.md5_employee,
       (n1.name_clean is not null),
       n1.name_clean,
       n1.first_name,
       n1.middle_name,
       n1.last_name,
       n1.suffix,
       'NJ',
       2,
       t1.data_source_url
from tmp_nj_1nf t1
         left join usa_raw.nj_state_employees_salaries__names_clean as n1 on t1.full_name = n1.full_name
group by t1.md5_employee; # 174_413

update tmp_nj_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 1_064_003

#[x] job_titles ========================================================================================================

-- checks
select t1.master_title_desc, count(*) as total
from tmp_nj_1nf t1
group by t1.master_title_desc
# order by t1.position asc
# 3_232
order by total desc;

select count(distinct t1.master_title_desc)
# select distinct t1.title
from tmp_nj_1nf as t1
         join pess_job_titles as j1
              on t1.master_title_desc = j1.raw_job_title;
# 278

select *
from tmp_nj_1nf
where master_title_desc = '';

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.master_title_desc,
       (n1.master_title_desc_clean is not null) as cleaned,
       n1.master_title_desc_clean               as clean_job_title
from tmp_nj_1nf as t1
         left join usa_raw.nj_state_employees_salaries__titles_clean as n1
                   on t1.master_title_desc = n1.master_title_desc
group by t1.master_title_desc; # 2_954 = 3_232 - 278

update tmp_nj_1nf t1
    left join pess_job_titles j1
    on t1.master_title_desc = j1.raw_job_title
set t1.job_title_id = j1.id;
# 1_064_003

#[x] agencies ==========================================================================================================

-- checks
select master_department_agency_desc as agency
from usa_raw.nj_state_employees_salaries
where master_department_agency_desc regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 11 - 2 = 9

select count(distinct md5_agency)
from tmp_nj_1nf;
# 42

select distinct master_department_agency_desc,
                length(master_department_agency_desc) as length,
                trim(master_department_agency_desc)   as trimmed
from tmp_nj_1nf
order by master_department_agency_desc asc;

select distinct master_department_agency_desc
from tmp_nj_1nf;
# 42

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, limpar_uuid, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.master_department_agency_desc,
       (n1.agency_clean is not null) as cleaned,
       ifnull(n1.agency_clean, t1.master_department_agency_desc),
       n1.limpar_UUID,
       2,
       t1.data_source_url
from tmp_nj_1nf t1
         left join usa_raw.nj_state_employees_salaries_agencies_clean as n1
                   on t1.master_department_agency_desc = n1.agency
where n1.agency_clean is not null
group by t1.md5_agency; # 40

update tmp_nj_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 1_064_003

#[x] employee_work_years ===============================================================================================

-- checks
select count(distinct md5_ewy)
from tmp_nj_1nf; # 1_064_003

select count(distinct t1.md5_ewy)
from tmp_nj_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash; # 0

update tmp_nj_1nf
set ewy_id = null;

select distinct compensation_method
from tmp_nj_1nf
where agency_id is not null;

-- process
update tmp_nj_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, calendar_year, '', 'Salary', '', job_title_id, 2, id,
                            data_source_url))
where agency_id is not null; # 1_063_250

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, full_or_part_status, pay_type,
                                            hourly_rate, job_title_id, raw_dataset_table_id,
                                            raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.calendar_year,
       if(t1.compensation_method like 'part%', 'part-time', 'full-time'),
       if(t1.compensation_method like 'hourly', 'HOURLY',
          if(t1.compensation_method like '%salary', 'ANNUAL SALARY', null)),
       if(t1.compensation_method like 'hourly', t1.salary_hourly_rate, null),
       t1.job_title_id,
       2,
       t1.id,
       t1.data_source_url
from tmp_nj_1nf as t1
where t1.agency_id is not null; # 1_063_250

update tmp_nj_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 1_063_250

#[ ] compensations =====================================================================================================

-- checks
select master_ytd_earnings, trim(master_ytd_earnings) + 0
from tmp_nj_1nf;

select count(*)
from tmp_nj_1nf as t1
where t1.agency_id is not null
  and t1.master_ytd_regular_pay <> '0.00';

-- ytd_earnings
update tmp_nj_1nf as t1
set t1.md5_ytd_earnings = MD5(CONCAT_WS('+', t1.ewy_id, 27, t1.master_ytd_earnings, '', 1, '', 2, t1.data_source_url))
where t1.agency_id is not null; # 1_063_250

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_ytd_earnings, t1.ewy_id, 27, t1.master_ytd_earnings, 1, 2, t1.data_source_url
from tmp_nj_1nf as t1
where t1.agency_id is not null;
# 1_063_250

-- ytd_all_other_payments
update tmp_nj_1nf as t1
set t1.md5_ytd_all_other_payments = MD5(CONCAT_WS('+', t1.ewy_id, 26, t1.master_ytd_all_other_payments, '', 0, 1, 2,
                                                  t1.data_source_url))
where t1.agency_id is not null
  and t1.master_ytd_all_other_payments <> '0.00'; # 558_299

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, include_in_sum_for_total_comp, dataset_id,
                                       data_source_url)
select t1.md5_ytd_all_other_payments,
       t1.ewy_id,
       26,
       t1.master_ytd_all_other_payments,
       0,
       1,
       2,
       t1.data_source_url
from tmp_nj_1nf as t1
where t1.md5_ytd_all_other_payments is not null;
# 558_299

-- ytd_overtime_payments
update tmp_nj_1nf as t1
set t1.md5_ytd_overtime_payments = MD5(CONCAT_WS('+', t1.ewy_id, 25, t1.master_ytd_overtime_payments, '', 0, 1, 2,
                                                 t1.data_source_url))
where t1.agency_id is not null
  and t1.master_ytd_overtime_payments <> '0.00'; # 385_777

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, include_in_sum_for_total_comp, dataset_id,
                                       data_source_url)
select t1.md5_ytd_overtime_payments,
       t1.ewy_id,
       25,
       t1.master_ytd_overtime_payments,
       0,
       1,
       2,
       t1.data_source_url
from tmp_nj_1nf as t1
where t1.md5_ytd_overtime_payments is not null;
# 385_777

-- ytd_regular_pay
update tmp_nj_1nf as t1
set t1.md5_ytd_regular_pay = MD5(CONCAT_WS('+', t1.ewy_id, 24, t1.master_ytd_regular_pay, '', 0, 1, 2,
                                           t1.data_source_url))
where t1.agency_id is not null
  and t1.master_ytd_regular_pay <> '0.00'; # 1_008_448

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, include_in_sum_for_total_comp, dataset_id,
                                       data_source_url)
select t1.md5_ytd_regular_pay,
       t1.ewy_id,
       24,
       t1.master_ytd_regular_pay,
       0,
       1,
       2,
       t1.data_source_url
from tmp_nj_1nf as t1
where t1.md5_ytd_regular_pay is not null;
# 1_008_448