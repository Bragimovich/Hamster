#= checks ==============================================================================================================

select distinct data_source_url
from state_salaries__raw.ga_employee_salaries;

select count(*)
from state_salaries__raw.ga_employee_salaries;
where deleted = 0;

select organization as agency
from state_salaries__raw.ga_employee_salaries
where organization regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc;

select organization as agency
from state_salaries__raw.ga_employee_salaries
where organization not regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc;

select count(*)
from state_salaries__raw.ga_employee_salaries
where organization not regexp 'college|universit|academ|school|institut';

select *
from state_salaries__raw.ga_employee_salaries
where deleted = 1;
# 0

select distinct travel
from state_salaries__raw.ga_employee_salaries;

select distinct fiscal_year
from tmp_ga_1nf;
# 2013-2022

#[x] create ============================================================================================================

CREATE TABLE tmp_ga_1nf LIKE state_salaries__raw.ga_employee_salaries;

alter table tmp_ga_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_ga_1nf;

alter table tmp_ga_1nf
    drop column run_id,
    drop column created_by,
    drop column created_at,
    drop column updated_at,
    drop column touched_run_id,
    drop column deleted,
    drop column md5_hash;

alter table tmp_ga_1nf
    add column `md5_employee` varchar(255) null after id,
    add column `employee_id`  bigint       null after md5_employee,
    add column `job_title_id` bigint       null after employee_id,
    add column `md5_agency`   varchar(255) null after job_title_id,
    add column `agency_id`    bigint       null after md5_agency,
    add column `md5_ewy`      varchar(255) null after agency_id,
    add column `ewy_id`       bigint       null after md5_ewy,
    add column `md5_salary`   varchar(255) null after ewy_id,
    add column `md5_travel`   varchar(255) null after md5_salary,
    add index `md5_employee` (`md5_employee`),
    add index `md5_agency` (`md5_agency`),
    add index `md5_ewy` (`md5_ewy`);

insert into tmp_ga_1nf (id, `name`, title, salary, travel, `organization`, fiscal_year, data_source_url)
select g1.id,
       g1.name,
       g1.title,
       g1.salary,
       g1.travel,
       g1.organization,
       g1.fiscal_year,
       g1.data_source_url
from state_salaries__raw.ga_employee_salaries g1
where organization not regexp 'college|universit|academ|school|institut';
# 3_404_703

select count(*)
from tmp_ga_1nf
where name = 'STUDENT EMPLOYEE';
# 165

delete
from tmp_ga_1nf
where name = 'STUDENT EMPLOYEE';

#[x] initial data =====================================================================================================

explain state_salaries__raw.ga_employee_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.state_salaries__raw', 'ga_employee_salaries%', 'Open Georgia', 'Scrape',
        'https://open.ga.gov/download.html', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('ga_employee_salaries', 13, 'Alim L.');

insert ignore into pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
values ('Travel', 1, 'Travel Expense', 'Alim L.');

update tmp_ga_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', t1.name, lower(trim(t1.organization)), t1.data_source_url)); # 3_404_703

update tmp_ga_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', t1.name, lower(trim(t1.organization)), lower(trim(t1.title)),
                                    t1.data_source_url)); # 3_404_703

update tmp_ga_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.organization)), t1.data_source_url));
# 3_404_538

#[x] employees =========================================================================================================

-- checks
select distinct `name`
from tmp_ga_1nf; # 768_170 - full_names

select count(*)
from tmp_ga_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash; # 0

select count(distinct t1.md5_employee) as total_employee
from tmp_ga_1nf t1;
# 871_414 - full_name+department

-- duplicates check
select `name`, `organization`, fiscal_year, count(*) as count
from tmp_ga_1nf
group by `name`, `organization`, fiscal_year
having count > 1
order by count desc;

select `name`, `organization`, fiscal_year, group_concat(title), count(*) as count
from tmp_ga_1nf
group by md5_employee, fiscal_year
having count > 1
order by count desc;

select sum(count)
from (select count(*) as count
      from tmp_ga_1nf
      group by md5_employee, fiscal_year
      having count > 1
      order by count desc) as tmp;

update tmp_ga_1nf
set employee_id = null;

-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, state, dataset_id, data_source_url)
select t1.md5_employee,
       (g1.name_clean is not null),
       g1.name_clean,
       g1.first_name,
       g1.middle_name,
       g1.last_name,
       g1.suffix,
       'GA',
       13,
       t1.data_source_url
from tmp_ga_1nf t1
         join state_salaries__raw.ga_employee_salaries__names_clean g1 on t1.name = g1.name
group by t1.md5_employee; # 871_414

update tmp_ga_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 3_404_538

#[x] job_titles ========================================================================================================

-- checks
select t1.title, count(*) as count
from tmp_ga_1nf t1
group by t1.title
# order by t1.title asc;
# 4_175
order by count desc;

select count(distinct t1.title)
# select distinct t1.title
from tmp_ga_1nf t1
         join pess_job_titles j1
              on t1.title = j1.raw_job_title;
# 630

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.title, (g1.title_clean is not null) as cleaned, ifnull(g1.title_clean, t1.title) as clean_job_title
from tmp_ga_1nf t1
         left join state_salaries__raw.ga_employee_salaries__titles_clean g1
                   on t1.title = g1.title
group by t1.title; # 3_545 = 4_175 - 630

update tmp_ga_1nf t1
    left join pess_job_titles j1
    on t1.title = j1.raw_job_title
set t1.job_title_id = j1.id;
# 3_404_538

#[x] agencies ==========================================================================================================

-- checks
select organization as agency
from state_salaries__raw.ga_employee_salaries
where organization regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 103

select count(distinct md5_agency)
from tmp_ga_1nf;
# 319

select distinct organization, length(organization) as length, trim(organization) as trimmed
from tmp_ga_1nf
order by organization asc;

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, pl_org_id, limpar_uuid,
                                  dataset_id, data_source_url)
select t1.md5_agency,
       t1.organization,
       (g1.organization_clean is not null) as cleaned,
       ifnull(g1.organization_clean, g1.organization),
       g1.pl_production_org_id,
       g1.limpar_org_id,
       13,
       t1.data_source_url
from tmp_ga_1nf t1
         left join state_salaries__raw.ga_employee_salaries__organizations_clean g1
                   on t1.organization = g1.organization
group by t1.md5_agency; # 319

update tmp_ga_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 3_404_538

#[x] employee_work_years ===============================================================================================

-- checks
select count(distinct md5_ewy)
from tmp_ga_1nf; # 3_404_538

select count(distinct t1.md5_ewy)
from tmp_ga_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash; # 0

update tmp_ga_1nf
set ewy_id = null;

-- process
update tmp_ga_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, fiscal_year, '', 'Salary', '', job_title_id, 13, id,
                            data_source_url)); # 3_404_538

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, job_title_id,
                                            raw_dataset_table_id, raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.fiscal_year,
       'Salary',
       t1.job_title_id,
       13,
       t1.id,
       t1.data_source_url
from tmp_ga_1nf t1; # 3_404_538

update tmp_ga_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 3_404_538

#[ ] compensations =====================================================================================================

-- salary
update tmp_ga_1nf t1
set t1.md5_salary = MD5(CONCAT_WS('+', t1.ewy_id, 2, t1.salary, '', 1, '', 13, t1.data_source_url));
# 3_404_538

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_salary, t1.ewy_id, 2, t1.salary, 1, 13, t1.data_source_url
from tmp_ga_1nf t1;
# 3_404_538

-- travel
update tmp_ga_1nf t1
set t1.md5_travel = MD5(CONCAT_WS('+', t1.ewy_id, 23, t1.travel, '', 0, '', 13, t1.data_source_url));
# 3_404_538

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_travel, t1.ewy_id, 23, t1.travel, 0, 13, t1.data_source_url
from tmp_ga_1nf t1;
# 3_404_538
