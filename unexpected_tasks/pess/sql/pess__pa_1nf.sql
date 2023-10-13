#[x] create ============================================================================================================

CREATE TABLE tmp_pa_1nf LIKE usa_raw.pa_public_employee_salaries;

alter table tmp_pa_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_pa_1nf;

alter table tmp_pa_1nf
    drop column state,
    drop column `date`,
    drop column scrape_dev_name,
    drop column updated_at,
    drop column created_at,
    drop column scrape_frequency,
    drop column run_id;

alter table tmp_pa_1nf
    add column `md5_employee` varchar(255) null after id,
    add column `employee_id`  bigint       null after md5_employee,
    add column `job_title_id` bigint       null after employee_id,
    add column `md5_agency`   varchar(255) null after job_title_id,
    add column `agency_id`    bigint       null after md5_agency,
    add column `md5_ewy`      varchar(255) null after agency_id,
    add column `ewy_id`       bigint       null after md5_ewy,
    add column `md5_salary`   varchar(255) null after ewy_id,
    add column `md5_wage`     varchar(255) null after md5_salary,
    add index `md5_employee` (`md5_employee`),
    add index `md5_agency` (`md5_agency`),
    add index `md5_ewy` (`md5_ewy`);

select p1.agency as agency, count(*)
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2
              on p1.id = p2.id
where agency_name regexp 'coll'
group by agency
order by agency asc; # 262

insert into tmp_pa_1nf (id, last_name, first_name, full_name_concat, position, annual_salary, wage, `date`, `year`,
                        agency_name, data_source_url)
select p2.id,
       p2.last_name,
       p2.first_name,
       p2.full_name_concat,
       if(p2.position = 'null', null, p2.position),
       cast(p1.annual_pay as decimal(10, 2)),
       # if(p2.annual_salary = 'null', null, CAST(REPLACE(REPLACE(p2.annual_salary, "$", ""), ",", "") AS decimal(10, 2))),
       if(p2.wage = 'null', null, p2.wage),
       p2.date,
       p2.`year`,
       p2.agency_name,
       'http://pennwatch.pa.gov/employees/Pages/Employee-Salaries.aspx'
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2
              on p1.id = p2.id
where p2.agency_name not regexp 'coll'
  and p2.first_name not regexp 'correction|house|board'
  and p2.date not in ('08/15/2019', '11/15/2022');
# 434_637

#[x] initial data =====================================================================================================

explain usa_raw.pa_public_employee_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'pa_public_employee_salaries%', 'Pennsylvania Public Employee Salary', 'Scrape',
        'http://pennwatch.pa.gov/employees/Pages/Employee-Salaries.aspx', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('pa_public_employee_salaries', 12, 'Alim L.');

update tmp_pa_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', lower(trim(t1.last_name)), lower(trim(t1.first_name)),
                                    lower(trim(t1.agency_name)), lower(trim(t1.position)),
                                    t1.data_source_url)); # 434_637

DELETE t1
# select t1.id
FROM tmp_pa_1nf t1,
     tmp_pa_1nf t2
WHERE t1.id > t2.id
  AND t1.year = t2.year
  and t1.md5_employee = t2.md5_employee
  and t1.annual_salary <=> t2.annual_salary;

update tmp_pa_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.agency_name)), t1.data_source_url));
# 434_637

#[x] employees =========================================================================================================

-- checks
select distinct `year`
from tmp_pa_1nf; # 2019 - 2023

select distinct last_name, first_name
from tmp_pa_1nf; # 116_397 - full_names, 16_722 - job_titles

select count(*)
from tmp_pa_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;
# 0

-- full_name+agency+job_title = 175_430
select count(distinct t1.md5_employee) as total_employee
from tmp_pa_1nf t1;

select agency_name
from tmp_pa_1nf
where length(agency_name) <> length(trim(agency_name));

-- duplicates on full_name+agency+job_title
select md5_employee, count(*) as count
from tmp_pa_1nf
group by md5_employee, `year`
having count > 1
order by count desc; # 444

select sum(count)
from (select count(*) as count
      from tmp_pa_1nf
      group by md5_employee, `year`
      having count > 1
      order by count desc) as tmp;

update tmp_pa_1nf
set employee_id = null;

-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, state, dataset_id, data_source_url)
select t1.md5_employee,
       (p1.name_clean is not null),
       p1.name_clean,
       p1.first_name,
       p1.middle_name,
       p1.last_name,
       p1.suffix,
       'PA',
       12,
       t1.data_source_url
from tmp_pa_1nf t1
         left join usa_raw.pa_public_employee_salaries__names_clean p1 on t1.full_name_concat = p1.name
group by t1.md5_employee; # 175_430

update tmp_pa_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 434_637

#[x] job_titles ========================================================================================================

-- checks
select t1.position, count(*) as total
from tmp_pa_1nf t1
group by t1.position
# order by t1.position asc
# 16_019
order by total desc;

select count(distinct t1.position)
# select distinct t1.title
from tmp_pa_1nf t1
         join pess_job_titles j1
              on t1.position = j1.raw_job_title;
# 1_086

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.position,
       (p1.position_clean <> '')                                  as cleaned,
       if(p1.position_clean = '', t1.position, p1.position_clean) as clean_job_title
from tmp_pa_1nf as t1
         left join usa_raw.pa_public_employee_salaries__titles_clean as p1
                   on t1.position = p1.position
where t1.position is not null
group by t1.position; # 14_932 = 16_018 - 1_086

update tmp_pa_1nf t1
    left join pess_job_titles j1
    on t1.position = j1.raw_job_title
set t1.job_title_id = j1.id;
# 434_637

#[x] agencies ==========================================================================================================

-- checks
select agency_name as agency
from usa_raw.pa_public_employee_salaries
where agency_name regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 11 - 2 = 9

select count(distinct md5_agency)
from tmp_pa_1nf;
# 65

select distinct agency_name, length(agency_name) as length, trim(agency_name) as trimmed
from tmp_pa_1nf
order by agency_name asc;

select distinct agency_name
from tmp_pa_1nf;
# 65

select p1.agency, p2.agency_name_clean, p1.limpar_org_id
from tmp_pa_1nf as t1
         join (select distinct id, agency, limpar_org_id
               from usa_raw.pa_public_employee_salaries__cleaned_by_owen) as p1
         left join usa_raw.pa_public_employee_salaries__department_clean p2 on p1.agency = p2.agency_name;

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, limpar_uuid, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.agency_name,
       0 as cleaned,
       t1.agency_name,
       p1.limpar_org_id,
       12,
       t1.data_source_url
from tmp_pa_1nf t1
         left join (select distinct agency, limpar_org_id
                    from usa_raw.pa_public_employee_salaries__cleaned_by_owen) as p1
                   on t1.agency_name = p1.agency
group by t1.md5_agency; # 65

update tmp_pa_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 434_637

#[x] employee_work_years ===============================================================================================

-- checks
select count(distinct md5_ewy)
from tmp_pa_1nf; # 434_637

select count(distinct t1.md5_ewy)
from tmp_pa_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash;

update tmp_pa_1nf
set ewy_id = null;

select *
from tmp_pa_1nf
where annual_salary = 0;
and wage is not null;

-- process
update tmp_pa_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '', job_title_id, 12, id,
                            data_source_url)); # 434_637

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, hourly_rate,
                                            job_title_id, raw_dataset_table_id, raw_dataset_table_id_raw_id,
                                            data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.year,
       if(wage is null, 'Salary', if(wage regexp 'Hour', 'Hourly', 'Daily'))     as pay_type,
       if(wage is null, null,
          if(wage regexp 'Hour', trim(replace(substr(wage, 1, instr(wage, '/') - 1), "$", "")),
             trim(replace(substr(wage, 1, instr(wage, '/') - 1), "$", "")) / 8)) as hourly_rate,
       t1.job_title_id,
       12,
       t1.id,
       t1.data_source_url
from tmp_pa_1nf t1; # 434_637

update tmp_pa_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 434_637

#[ ] compensations =====================================================================================================

-- annual_salary
update tmp_pa_1nf t1
set t1.md5_annual_salary = MD5(CONCAT_WS('+', t1.ewy_id, 3, t1.annual_salary, '', (t1.wage is null), '', 12,
                                         t1.data_source_url));
# 434_637

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_annual_salary, t1.ewy_id, 3, t1.annual_salary, (t1.wage is null), 12, t1.data_source_url
from tmp_pa_1nf t1;
# 434_637

#= extra checks ========================================================================================================

select distinct hire_date, str_to_date(hire_date, '%m/%d/%Y')
from usa_raw.pa_public_employee_salaries__cleaned_by_owen;

update usa_raw.pa_public_employee_salaries__cleaned_by_owen p1
set p1.hire_date = str_to_date(p1.hire_date, '%m/%d/%Y');

select count(*)
from usa_raw.pa_public_employee_salaries__cleaned_by_owen p1
         join usa_raw.pa_public_employee_salaries p2 on p1.id = p2.id; # 530_498

select p1.agency, p2.agency_name_clean, p1.limpar_org_id
from (select distinct agency, limpar_org_id from usa_raw.pa_public_employee_salaries__cleaned_by_owen) as p1
         left join usa_raw.pa_public_employee_salaries__department_clean p2 on p1.agency = p2.agency_name;

select p1.first_name, p1.last_name, p2.first_name, p2.last_name, p3.first_name, p3.middle_name, p3.last_name
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2 on p1.id = p2.id
         join usa_raw.pa_public_employee_salaries__names_clean as p3 on p2.full_name_concat = p3.name
where p1.first_name <> p3.first_name
   or p1.last_name <> p3.last_name;

select p1.first_name, p1.last_name, p2.first_name, p2.last_name, p3.first_name, p3.middle_name, p3.last_name
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2 on p1.id = p2.id
         join usa_raw.pa_public_employee_salaries__names_clean as p3 on p2.full_name_concat = p3.name
where p2.first_name regexp 'correction|house|board';

select wage,
       substr(wage, 1, instr(wage, '/') - 1)                         as currency,
       trim(replace(substr(wage, 1, instr(wage, '/') - 1), "$", "")) as `decimal`,
       if(wage like '%hour%', 'Hour', if(wage like '%day%', 'Day', null))
from usa_raw.pa_public_employee_salaries
where wage regexp 'hour|day';

select wage
from usa_raw.pa_public_employee_salaries
where wage not regexp 'hour|day|null|board';

select p2.wage
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2
              on p1.id = p2.id
where p2.wage not regexp 'hour|day|null';

select p2.annual_salary, p1.annual_pay
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2
              on p1.id = p2.id
where REPLACE(REPLACE(p2.annual_salary, "$", ""), ",", "") = p1.annual_pay;

select p1.job_title, p2.position
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2
              on p1.id = p2.id
where p2.agency_name not regexp 'coll'
  and p2.first_name not regexp 'correction|house|board';
and p2.position = 'null';

select p1.job_title, p2.position, p3.position_clean
from usa_raw.pa_public_employee_salaries__cleaned_by_owen as p1
         join usa_raw.pa_public_employee_salaries as p2 on p1.id = p2.id
         join usa_raw.pa_public_employee_salaries__titles_clean as p3 on p2.position = p3.position
where p1.job_title <> p2.position;

select *
from tmp_pa_1nf
where annual_salary is null
  and wage is null;

select t1.full_name_concat,
       t1.agency_name,
       t1.position,
       t1.year,
       t1.date,
       group_concat(t1.annual_salary),
       count(*) as total
from tmp_pa_1nf as t1
group by t1.full_name_concat, t1.agency_name, t1.position, t1.year
order by total desc;

select year, date, count(*)
from tmp_pa_1nf
group by year, date
order by year;

select year,
       md5_employee,
       full_name_concat,
       group_concat(annual_salary) as report_dates,
       group_concat(id),
       count(*)                    as total
from tmp_pa_1nf
group by year, md5_employee, annual_salary
having total > 1
order by total desc;

update tmp_pa_1nf as t1
    join usa_raw.pa_public_employee_salaries as p1
    on t1.id = p1.id
set t1.date = p1.date;

select distinct `date`
from usa_raw.pa_public_employee_salaries
where `date` not in ('08/15/2019', '11/15/2022')