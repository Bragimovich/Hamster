#= checks ==============================================================================================================

select distinct data_source_url
from state_salaries__raw.ar_employee_salaries
where deleted = 0; # single

select agency
from state_salaries__raw.ar_employee_salaries
where agency regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 4 - exclude

select distinct fiscal_year
from state_salaries__raw.ar_employee_salaries;
# 2013-2024

#[x] create&fill =======================================================================================================

CREATE TABLE tmp_ar_1nf LIKE state_salaries__raw.ar_employee_salaries;

alter table tmp_ar_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_ar_1nf;

alter table tmp_ar_1nf
    drop column run_id,
    drop column data_year,
    drop column pay_class_category,
    drop column pay_scale_type,
    drop column position_number,
    drop column career_service_date,
    drop column extra_help_flag,
    drop column class_code,
    drop column pay_grade,
    drop column created_by,
    drop column created_at,
    drop column updated_at,
    drop column touched_run_id,
    drop column deleted,
    drop column is_active,
    drop column md5_hash;

alter table tmp_ar_1nf
    add column `md5_employee`      varchar(255) null after id,
    add column `employee_id`       bigint       null after md5_employee,
    add column `job_title_id`      bigint       null after employee_id,
    add column `md5_agency`        varchar(255) null after job_title_id,
    add column `agency_id`         bigint       null after md5_agency,
    add column `md5_ewy`           varchar(255) null after agency_id,
    add column `ewy_id`            bigint       null after md5_ewy,
    add column `md5_annual_salary` varchar(255) null after ewy_id,
    add index `md5_employee` (`md5_employee`),
    add index `md5_agency` (`md5_agency`),
    add index `md5_ewy` (`md5_ewy`);

insert into tmp_ar_1nf (id, fiscal_year, agency, position_title, employee_name, gender, race,
                        percent_of_time, annual_salary, data_source_url)
select id,
       fiscal_year,
       agency,
       position_title,
       employee_name,
       gender,
       race,
       percent_of_time,
       annual_salary,
       'https://www.ark.org/dfa/transparency/employee_compensation.php'
from state_salaries__raw.ar_employee_salaries
where agency not regexp 'college|universit|academ|school|institut'
  and deleted = 0;
# 327_273

#[x] initial data =====================================================================================================

explain state_salaries__raw.ar_employee_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.state_salaries__raw', 'ar_employee_salaries%', 'State of Arkansas Employee Salaries', 'Scrape',
        'https://www.ark.org/dfa/transparency/employee_compensation.php', 'Alim L.');

insert ignore into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('ar_employee_salaries', 17, 'Alim L.');

update tmp_ar_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', lower(trim(t1.employee_name)), lower(trim(t1.gender)), lower(trim(t1.race)),
                                    lower(trim(t1.agency)), t1.data_source_url)); # 327_273

update tmp_ar_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.agency)), t1.data_source_url));
# 327_273

#[x] employees =========================================================================================================

-- checks
select distinct employee_name
from tmp_ar_1nf; # 84_694 - full_names

select count(*)
from tmp_ar_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;
# 0

-- full_name+agency = 98_406
select count(distinct t1.md5_employee) as total_employee
from tmp_ar_1nf t1;

-- duplicates on full_name+agency+job_title
select md5_employee, employee_name, group_concat(agency), group_concat(position_title), count(*) as total
from tmp_ar_1nf
group by md5_employee, fiscal_year
having total > 1
order by total desc; # 18

select employee_name,
       group_concat(distinct agency),
       fiscal_year,
       group_concat(position_title),
       group_concat(annual_salary),
       count(*) as count
from tmp_ar_1nf
group by employee_name, agency, fiscal_year
having count > 1
order by count desc;

select t1.employee_name, t1.position_title, t2.position_title
from tmp_ar_1nf as t1
         join tmp_ar_1nf as t2 on t1.md5_employee = t2.md5_employee
where t1.annual_salary = t2.annual_salary
  and t1.fiscal_year = t2.fiscal_year
  and t1.id > t2.id;

select sum(count)
from (select count(*) as count
      from tmp_ar_1nf
      group by md5_employee, fiscal_year
      having count > 1
      order by count desc) as tmp;

update tmp_ar_1nf
set employee_id = null;

select count(*)
from tmp_ar_1nf as t1
         left join state_salaries__raw.ar_employee_salaries__names_clean as n1 on t1.employee_name = n1.employee_name
where n1.employee_name is null;
# 0 - unmatched

-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, race, gender, state, dataset_id, data_source_url)
select t1.md5_employee,
       (n1.employee_name_clean is not null) as cleaned,
       n1.employee_name_clean,
       n1.first_name,
       n1.middle_name,
       n1.last_name,
       n1.suffix,
       t1.race,
       t1.gender,
       'AR',
       17,
       t1.data_source_url
from tmp_ar_1nf t1
         left join state_salaries__raw.ar_employee_salaries__names_clean as n1 on t1.employee_name = n1.employee_name
# where n1.full_name_clean is null
group by t1.md5_employee; # 98_406

update tmp_ar_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 327_273

#[x] job_titles ========================================================================================================

-- checks
select t1.position_title, count(*) as total
from tmp_ar_1nf t1
group by t1.position_title
# order by t1.position asc
# 4_219
order by total desc;

select count(distinct t1.position_title)
# select distinct t1.title
from tmp_ar_1nf as t1
         join pess_job_titles as j1
              on t1.position_title = j1.raw_job_title;
# 625

select *
from tmp_ar_1nf
where position_title = '';

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.position_title,
       (n1.position_title_clean is not null) as cleaned,
       n1.position_title_clean               as clean_job_title
from tmp_ar_1nf as t1
         left join state_salaries__raw.ar_employee_salaries__position_titles_clean as n1
                   on t1.position_title = n1.position_title
where t1.position_title is not null
group by t1.position_title; # 3_593 = 4_219 - 1(NULL) - 625

update tmp_ar_1nf t1
    left join pess_job_titles j1
    on t1.position_title = j1.raw_job_title
set t1.job_title_id = j1.id;
# 327_273

#[x] agencies ==========================================================================================================

-- checks
select agency as agency
from state_salaries__raw.ar_employee_salaries
where agency regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 2

select count(distinct md5_agency)
from tmp_ar_1nf;
# 169

select distinct agency, length(agency) as length, trim(agency) as trimmed
from tmp_ar_1nf
order by agency asc;

select distinct agency
from tmp_ar_1nf;
# 169

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.agency,
       (a1.agency_clean is not null) as cleaned,
       a1.agency_clean,
       17,
       t1.data_source_url
from tmp_ar_1nf t1
         left join state_salaries__raw.ar_employee_salaries__agencies_clean as a1 on t1.agency = a1.agency
group by t1.md5_agency; # 169

update tmp_ar_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 327_273

#[x] employee_work_years ===============================================================================================

-- checks
select count(distinct md5_ewy)
from tmp_ar_1nf; # 327_273

select count(distinct t1.md5_ewy)
from tmp_ar_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash; # 0

update tmp_ar_1nf
set ewy_id = null;

-- process
update tmp_ar_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, fiscal_year, '', 'Salary', '', job_title_id, 17, id,
                            data_source_url)); # 327_273

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, job_title_id,
                                            raw_dataset_table_id, raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.fiscal_year,
       'Salary' as pay_type,
       t1.job_title_id,
       17,
       t1.id,
       t1.data_source_url
from tmp_ar_1nf t1; # 327_273

update tmp_ar_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 327_273

#[x] compensations =====================================================================================================

-- salary
update tmp_ar_1nf as t1
set t1.md5_annual_salary = MD5(CONCAT_WS('+', t1.ewy_id, 3, t1.annual_salary, '', 1, '', 17, t1.data_source_url));
# 327_273

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_annual_salary, t1.ewy_id, 3, t1.annual_salary, 1, 17, t1.data_source_url
from tmp_ar_1nf as t1;
# 327_273
