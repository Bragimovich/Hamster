#[x] create ============================================================================================================

CREATE TABLE tmp_ky_1nf LIKE usa_raw.ky_public_employee_salaries;

alter table tmp_ky_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_ky_1nf;

alter table tmp_ky_1nf
    drop column state,
    drop column first_name,
    drop column middle_name,
    drop column last_name,
    drop column branch,
    drop column cabinet,
    drop column created_at,
    drop column updated_at,
    drop column data_response_source,
    drop column scrape_dev_name,
    drop column scrape_frequency,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column expected_scrape_frequency,
    drop column dataset_name_prefix,
    drop column scrape_status,
    drop column pl_gather_task_id,
    drop column created_by,
    drop column md5_hash,
    drop column run_id;

alter table tmp_ky_1nf
    add column `md5_employee` varchar(255) null after id,
    add column `employee_id`  bigint       null after md5_employee,
    add column `job_title_id` bigint       null after employee_id,
    add column `md5_agency`   varchar(255) null after job_title_id,
    add column `agency_id`    bigint       null after md5_agency,
    add column `md5_ewy`      varchar(255) null after agency_id,
    add column `ewy_id`       bigint       null after md5_ewy,
    add column `md5_salary`   varchar(255) null after ewy_id,
    add index `md5_employee` (`md5_employee`),
    add index `md5_agency` (`md5_agency`),
    add index `md5_ewy` (`md5_ewy`);

select department as agency
from usa_raw.ky_public_employee_salaries
where department regexp 'college|university'
group by agency
order by agency asc;

insert into tmp_ky_1nf (id, `year`, full_name, title, department, salary, data_source_url)
select k1.id,
       k1.`year`,
       k1.full_name,
       k1.title,
       k1.department,
       k1.salary,
       k1.data_source_url
from usa_raw.ky_public_employee_salaries k1
where department not regexp 'college|university';
# 93_881

#[x] initial data =====================================================================================================

explain usa_raw.ky_public_employee_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'ky_public_employee_salaries%', 'Kentucky Public Employee Salaries', 'Scrape',
        'https://transparency.ky.gov/search/Pages/SalarySearch.aspx#/salary', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('ky_public_employee_salaries', 11, 'Alim L.');

insert ignore into pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
values ('Salary', 1, 'Salary', 'Alim L.');

update tmp_ky_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', t1.full_name, lower(trim(t1.department)), t1.data_source_url)); # 93_881

update tmp_ky_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.department)), t1.data_source_url));
# 93_881

#[x] employees =========================================================================================================

-- checks
select distinct `year`
from tmp_ky_1nf; # 2019, 2022, 2023

select distinct title
from tmp_ky_1nf; # 54_113 - full_names, 2_259 - job_titles

select count(*)
from tmp_ky_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash; # 0

select count(distinct t1.md5_employee) as total_employee
from tmp_ky_1nf t1;
# 58_117 - full_name+department

select department
from tmp_ky_1nf
where length(department) <> length(trim(department));

-- duplicates on full_name+department
select md5_employee, count(*) as count
from tmp_ky_1nf
group by md5_employee, `year`
having count > 1
order by count desc; # 111

select sum(count)
from (select count(*) as count
      from tmp_ky_1nf
      group by md5_employee, `year`
      having count > 1
      order by count desc) as tmp;

update tmp_ky_1nf
set employee_id = null;

-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, state, dataset_id, data_source_url)
select t1.md5_employee,
       (k1.full_name_clean is not null),
       k1.full_name_clean,
       k1.first_name,
       ifnull(k1.middle_name, ''),
       k1.last_name,
       ifnull(k1.suffix, ''),
       'KY',
       11,
       t1.data_source_url
from tmp_ky_1nf t1
         join usa_raw.ky_public_employee_salaries__names_clean k1 on t1.full_name = k1.full_name
group by t1.md5_employee; #

update tmp_ky_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 93_881

#[x] job_titles ========================================================================================================

-- checks
select t1.title, count(*) as count
from tmp_ky_1nf t1
group by t1.title
order by t1.title asc;
# 2_259
# order by count desc;

select count(distinct t1.title)
# select distinct t1.title
from tmp_ky_1nf t1
         join pess_job_titles j1
              on t1.title = j1.raw_job_title;
# 316

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.title, (k1.title_clean is not null) as cleaned, ifnull(k1.title_clean, t1.title) as clean_job_title
from tmp_ky_1nf t1
         left join usa_raw.ky_public_employee_salaries__title_clean k1
                   on t1.title = k1.title
group by t1.title; # 1_943 = 2_259 - 316

update tmp_ky_1nf t1
    left join pess_job_titles j1
    on t1.title = j1.raw_job_title
set t1.job_title_id = j1.id;
# 93_881

#[x] agencies ==========================================================================================================

-- checks
select department as agency
from usa_raw.ky_public_employee_salaries
where department regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 11 - 2 = 9

select count(distinct md5_agency)
from tmp_ky_1nf;
# 184

select distinct department, length(department) as length, trim(department) as trimmed
from tmp_ky_1nf
order by department asc;

select distinct department
from tmp_ky_1nf;
# 184

select 'a' = 'a  ';
# 1

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, limpar_uuid, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.department,
       (k1.department_clean is not null) as cleaned,
       ifnull(k1.department_clean, k1.department),
       k2.limpar_org_id,
       11,
       t1.data_source_url
from tmp_ky_1nf t1
         left join usa_raw.ky_public_employee_salaries__department_clean k1
                   on t1.department = k1.department
         left join usa_raw.ky_public_employee_salaries__departments_matched k2
                   on t1.department = k2.department
group by t1.md5_agency; #184

update tmp_ky_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 93_881

#[ ] employee_work_years ===============================================================================================

-- checks
select distinct title
from tmp_ky_1nf;

select count(distinct md5_ewy)
from tmp_ky_1nf; # 241_681

select count(distinct t1.md5_ewy)
from tmp_ky_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash;

update tmp_ky_1nf
set ewy_id = null;

-- process
update tmp_ky_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '', job_title_id, 11, id,
                            data_source_url)); # 93_881

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, job_title_id,
                                            raw_dataset_table_id, raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.year,
       'Salary',
       t1.job_title_id,
       11,
       t1.id,
       t1.data_source_url
from tmp_ky_1nf t1; # 93_881

update tmp_ky_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 93_881

#[ ] compensations =====================================================================================================

-- salary
update tmp_ky_1nf t1
set t1.md5_salary = MD5(CONCAT_WS('+', t1.ewy_id, 2, t1.salary, '', 1, '', 11, t1.data_source_url));
# 93_881

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_salary, t1.ewy_id, 2, t1.salary, 1, 11, t1.data_source_url
from tmp_ky_1nf t1;
# 93_881
