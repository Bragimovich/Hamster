#= checks ==============================================================================================================

select distinct data_source_url
from usa_raw.nc_state_employee_salaries; # single

select agency as agency
from usa_raw.nc_state_employee_salaries
where agency regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 2 - include

select distinct `year`
from usa_raw.nc_state_employee_salaries;
# 2023

#[x] create&fill =======================================================================================================

CREATE TABLE tmp_nc_1nf LIKE usa_raw.nc_state_employee_salaries;

alter table tmp_nc_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_nc_1nf;

alter table tmp_nc_1nf
    drop column first_name,
    drop column middle_name,
    drop column last_name,
    drop column last_action,
    drop column `checksum`,
    drop column num_in_group,
    drop column `active`,
    drop column scrape_dev_name,
    drop column created_at,
    drop column updated_at,
    drop column scrape_frequency,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column expected_scrape_frequency;

alter table tmp_nc_1nf
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

insert into tmp_nc_1nf (id, full_name, agency, job_title, salary, `YEAR`, data_source_url)
select n1.id,
       n1.full_name,
       n1.agency,
       n1.job_title,
       n1.salary,
       n1.YEAR,
       n1.data_source_url
from usa_raw.nc_state_employee_salaries as n1
where n1.agency not regexp 'college|universit|academ|school|institut';
# 82_272

#[x] initial data =====================================================================================================

explain usa_raw.nc_state_employee_salaries;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'nc_state_employee_salaries%', 'North Carolina State Employee Salaries', 'Scrape',
        'https://www.newsobserver.com/news/databases/state-pay/article11865482.html?appSession=10L2P7H2A9COKL3KM53179ULA437447541NE2OIR323ZMIVTJ02H45OVKZQUU5QTNQTYZFO21433A4I79O16YE5779FTI8J61EK8O3069U64PL21MF6S23513G4KK7FW&cbSearchAgain=true',
        'Alim L.');

insert ignore into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('nc_state_employee_salaries', 16, 'Alim L.');

update tmp_nc_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', lower(trim(t1.full_name)), lower(trim(t1.agency)),
                                    t1.data_source_url)); # 82_272


update tmp_nc_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.agency)), t1.data_source_url));
# 82_272

#[x] employees =========================================================================================================

-- checks
select distinct full_name
from tmp_nc_1nf; # 82_162 - full_names

select count(*)
from tmp_nc_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;
# 0

-- full_name+agency = 82_254
select count(distinct t1.md5_employee) as total_employee
from tmp_nc_1nf t1;

select full_name
from tmp_nc_1nf
where length(full_name) <> length(trim(full_name));

-- duplicates on full_name+agency+job_title
select md5_employee, full_name, group_concat(agency), group_concat(job_title), count(*) as total
from tmp_nc_1nf
group by md5_employee, `year`
having total > 1
order by total desc; # 18

select full_name,
       group_concat(distinct agency),
       year,
       group_concat(job_title),
       group_concat(salary),
       count(*) as count
from tmp_nc_1nf
group by full_name, agency, year
having count > 1
order by count desc;

select sum(count)
from (select count(*) as count
      from tmp_nc_1nf
      group by md5_employee, `year`
      having count > 1
      order by count desc) as tmp;

update tmp_nc_1nf
set employee_id = null;

select count(*)
from tmp_nc_1nf as t1
         left join usa_raw.nc_state_employee_salaries__names_clean as n1 on t1.full_name = n1.full_name
where n1.full_name is null;
# 0


-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, state, dataset_id, data_source_url)
select t1.md5_employee,
       (n1.full_name_clean is not null) as cleaned,
       n1.full_name_clean,
       n1.first_name,
       n1.middle_name,
       n1.last_name,
       n1.suffix,
       'NC',
       16,
       t1.data_source_url
from tmp_nc_1nf t1
         left join usa_raw.nc_state_employee_salaries__names_clean as n1 on t1.full_name = n1.full_name
# where n1.full_name_clean is null
group by t1.md5_employee; # 82_254

update tmp_nc_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 82_254

#[x] job_titles ========================================================================================================

-- checks
select t1.job_title, count(*) as total
from tmp_nc_1nf t1
group by t1.job_title
# order by t1.position asc
# 2_131
order by total desc;

select count(distinct t1.job_title)
# select distinct t1.title
from tmp_nc_1nf as t1
         join pess_job_titles as j1
              on t1.job_title = j1.raw_job_title;
# 498

select *
from tmp_nc_1nf
where job_title = '';

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.job_title,
       (n1.job_title_clean is not null) as cleaned,
       n1.job_title_clean               as clean_job_title
from tmp_nc_1nf as t1
         left join usa_raw.nc_state_employee_salaries__job_title_clean as n1
                   on t1.job_title = n1.job_title
where t1.job_title is not null
group by t1.job_title; # 1_632 = 2_131 - 1(NULL) - 498

update tmp_nc_1nf t1
    left join pess_job_titles j1
    on t1.job_title = j1.raw_job_title
set t1.job_title_id = j1.id;
# 82_272

#[x] agencies ==========================================================================================================

-- checks
select agency as agency
from usa_raw.nc_state_employee_salaries
where agency regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 2

select count(distinct md5_agency)
from tmp_nc_1nf;
# 44

select distinct agency, length(agency) as length, trim(agency) as trimmed
from tmp_nc_1nf
order by agency asc;

select distinct agency
from tmp_nc_1nf;
# 44

select t1.agency, p1.agency
from tmp_nc_1nf as t1
         join (select distinct id, agency, limpar_org_id
               from usa_raw.nc_state_employee_salaries__cleaned_by_owen) as p1 on t1.id = p1.id
where t1.agency <> p1.agency

select distinct t1.agency, p1.agency, p2.agency_clean, p1.limpar_org_id
from tmp_nc_1nf as t1
         join (select distinct id, agency, limpar_org_id
               from usa_raw.nc_state_employee_salaries__cleaned_by_owen) as p1 on t1.id = p1.id
         left join usa_raw.nc_state_employee_salaries__agency_clean as p2 on t1.agency = p2.agency
where p1.agency <> t1.agency; # agency cleaned by owen vs by us

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, limpar_uuid, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.agency,
       (p2.agency_clean is not null) as cleaned,
       p2.agency_clean,
       p1.limpar_org_id,
       16,
       t1.data_source_url
from tmp_nc_1nf t1
         join (select distinct id, limpar_org_id
               from usa_raw.nc_state_employee_salaries__cleaned_by_owen) as p1 on t1.id = p1.id
         left join usa_raw.nc_state_employee_salaries__agency_clean as p2 on t1.agency = p2.agency
group by t1.md5_agency; # 44

update tmp_nc_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 82_272

#[x] employee_work_years ===============================================================================================

-- checks
select count(distinct md5_ewy)
from tmp_nc_1nf; # 82_272

select count(distinct t1.md5_ewy)
from tmp_nc_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash; # 0

update tmp_nc_1nf
set ewy_id = null;

-- process
update tmp_nc_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '', job_title_id, 16, id,
                            data_source_url)); # 82_272

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, job_title_id,
                                            raw_dataset_table_id, raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.year,
       'Salary' as pay_type,
       t1.job_title_id,
       16,
       t1.id,
       t1.data_source_url
from tmp_nc_1nf t1; # 82_272

update tmp_nc_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 82_272

#[ ] compensations =====================================================================================================

-- checks
select salary, trim(salary) + 0
from tmp_nc_1nf;

-- salary
update tmp_nc_1nf as t1
set t1.md5_salary = MD5(CONCAT_WS('+', t1.ewy_id, 2, t1.salary, '', 1, '', 16, t1.data_source_url));
# 82_272

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_salary, t1.ewy_id, 2, t1.salary, 1, 16, t1.data_source_url
from tmp_nc_1nf as t1;
# 82_272
