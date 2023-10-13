#= checks ==============================================================================================================

select distinct data_source_url
from usa_raw.nm_state_employee_salary; # single

select organization as agency
from usa_raw.nm_state_employee_salary
where organization regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 2 - include

select distinct `year`
from usa_raw.nm_state_employee_salary;
# 2016-2019

#[x] create ============================================================================================================

CREATE TABLE tmp_nm_1nf LIKE usa_raw.nm_state_employee_salary;

alter table tmp_nm_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_nm_1nf;

alter table tmp_nm_1nf
    drop column first_name,
    drop column middle_name,
    drop column last_name,
    drop column position_mid_point,
    drop column created_at,
    drop column updated_at,
    drop column scrape_dev_name,
    drop column scrape_frequency,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column expected_scrape_frequency,
    drop column dataset_name_prefix,
    drop column scrape_status,
    drop column pl_gather_task_id;

alter table tmp_nm_1nf
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

insert into tmp_nm_1nf (id, `year`, full_name, position, branch, `organization`, position_hire_date, `status`, salary,
                        data_source_url)
select n2.id,
       n2.year,
       n2.full_name,
       n2.position,
       n2.branch,
       n2.organization,
       n2.position_hire_date,
       n2.status,
       n2.salary,
       n2.data_source_url
from usa_raw.nm_state_employee_salary__cleaned_by_owen as n1
         join usa_raw.nm_state_employee_salary as n2
              on n1.id = n2.id;
# 87_470

#[x] initial data =====================================================================================================

explain usa_raw.nm_state_employee_salary;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'nm_state_employee_salary%', 'New Mexico Public Employee Salaries', 'Scrape',
        'http://employees.newmexico.gov/Default.aspx?d=1579862234588.47', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('nm_state_employee_salary', 14, 'Alim L.');

update tmp_nm_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', lower(trim(t1.full_name)), lower(trim(t1.organization)),
                                    t1.data_source_url)); # 87_776

delete t1
# select t1.id
from tmp_nm_1nf t1,
     tmp_nm_1nf t2
where t1.id > t2.id
  and t1.year = t2.year
  and t1.md5_employee = t2.md5_employee
  and t1.position = t2.position
  and t1.salary = t2.salary;

update tmp_nm_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(trim(t1.organization)), t1.data_source_url));
# 87_470

#[x] employees =========================================================================================================

-- checks
select distinct full_name
from tmp_nm_1nf; # 30_255 - full_names

select count(*)
from tmp_nm_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;
# 0

-- full_name+agency = 32_684
select count(distinct t1.md5_employee) as total_employee
from tmp_nm_1nf t1;

select full_name
from tmp_nm_1nf
where length(full_name) <> length(trim(full_name));

-- duplicates on full_name+agency+job_title
select md5_employee, full_name, organization, group_concat(position), count(*) as total
from tmp_nm_1nf
group by md5_employee, `year`
having total > 1
order by total desc; # 49

select full_name,
       group_concat(distinct organization),
       year,
       group_concat(position),
       group_concat(salary),
       count(*) as count
from tmp_nm_1nf
group by full_name, organization, year
having count > 1
order by count desc;

select sum(count)
from (select count(*) as count
      from tmp_nm_1nf
      group by md5_employee, `year`
      having count > 1
      order by count desc) as tmp;

update tmp_nm_1nf
set employee_id = null;

select count(*)
from tmp_nm_1nf as t1
         left join usa_raw.nm_state_employee_salary__names_clean as n1 on t1.full_name = n1.full_name
where n1.full_name is null;


-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, last_name, state, dataset_id,
                                   data_source_url)
select t1.md5_employee,
       (n2.full_name_clean is not null),
       n2.full_name_clean,
       n1.first_name,
       n1.last_name,
       'NM',
       14,
       t1.data_source_url
from tmp_nm_1nf t1
         left join usa_raw.nm_state_employee_salary__cleaned_by_owen as n1 on t1.id = n1.id
         left join usa_raw.nm_state_employee_salary__names_clean as n2 on t1.full_name = n2.full_name
group by t1.md5_employee; # 32_684

update tmp_nm_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 87_470

#[x] job_titles ========================================================================================================

-- checks
select t1.position, count(*) as total
from tmp_nm_1nf t1
group by t1.position
# order by t1.position asc
# 1_465
order by total desc;

select count(distinct t1.position)
# select distinct t1.title
from tmp_nm_1nf as t1
         join pess_job_titles as j1
              on t1.position = j1.raw_job_title;
# 236

select *
from tmp_nm_1nf
where position = '';

select p1.job_title, p2.position, p3.position_clean
from usa_raw.nm_state_employee_salary__cleaned_by_owen as p1
         join usa_raw.nm_state_employee_salary as p2 on p1.id = p2.id
         join usa_raw.nm_state_employee_salary__job_titles_clean as p3 on p2.position = p3.position
where p1.job_title <> p2.position; # empty

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.position,
       (p1.position_clean <> '') as cleaned,
       p1.position_clean         as clean_job_title
from tmp_nm_1nf as t1
         left join usa_raw.nm_state_employee_salary__job_titles_clean as p1
                   on t1.position = p1.position
where t1.position <> ''
group by t1.position; # 1_228 = 1_464 - 236

update tmp_nm_1nf t1
    left join pess_job_titles j1
    on t1.position = j1.raw_job_title
set t1.job_title_id = j1.id;
# 87_470

#[x] agencies ==========================================================================================================

-- checks
select organization as agency
from usa_raw.nm_state_employee_salary
where organization regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 11 - 2 = 9

select count(distinct md5_agency)
from tmp_nm_1nf;
# 119

select distinct `organization`, length(organization) as length, trim(organization) as trimmed
from tmp_nm_1nf
order by `organization` asc;

select distinct `organization`
from tmp_nm_1nf;
# 119

select t1.organization, p1.organization
from tmp_nm_1nf as t1
         join (select distinct id, `organization`, limpar_org_id
               from usa_raw.nm_state_employee_salary__cleaned_by_owen) as p1 on t1.id = p1.id
where t1.organization <> p1.organization

select distinct t1.organization, p1.organization, p2.organization_clean, p1.limpar_org_id
from tmp_nm_1nf as t1
         join (select distinct id, `organization`, limpar_org_id
               from usa_raw.nm_state_employee_salary__cleaned_by_owen) as p1 on t1.id = p1.id
         left join usa_raw.nm_state_employee_salary__employers_clean as p2 on t1.organization = p2.organization
where p1.organization <> p2.organization_clean;

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, limpar_uuid, dataset_id,
                                  data_source_url)
select t1.md5_agency,
       t1.organization,
       (p2.organization_clean is not null) as cleaned,
       p2.organization_clean,
       p1.limpar_org_id,
       14,
       t1.data_source_url
from tmp_nm_1nf t1
         join (select distinct id, limpar_org_id
               from usa_raw.nm_state_employee_salary__cleaned_by_owen) as p1 on t1.id = p1.id
         left join usa_raw.nm_state_employee_salary__employers_clean as p2 on t1.organization = p2.organization
group by t1.md5_agency; # 119

update tmp_nm_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 87_470

#[x] employee_work_years ===============================================================================================

-- checks
select count(distinct md5_ewy)
from tmp_nm_1nf; # 87_470

select count(distinct t1.md5_ewy)
from tmp_nm_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash; # 0

update tmp_nm_1nf
set ewy_id = null;

-- process
update tmp_nm_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '', job_title_id, 14, id,
                            data_source_url)); # 87_470

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, job_title_id,
                                            raw_dataset_table_id, raw_dataset_table_id_raw_id, data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.year,
       'Salary' as pay_type,
       t1.job_title_id,
       14,
       t1.id,
       t1.data_source_url
from tmp_nm_1nf t1; # 87_470

update tmp_nm_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 87_470

#[x] compensations =====================================================================================================

-- checks
select salary, trim(salary) + 0
from tmp_nm_1nf;

-- salary
update tmp_nm_1nf as t1
set t1.md5_salary = MD5(CONCAT_WS('+', t1.ewy_id, 2, t1.salary, '', 1, '', 14, t1.data_source_url));
# 87_470

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_salary, t1.ewy_id, 2, trim(t1.salary) + 0, 1, 14, t1.data_source_url
from tmp_nm_1nf as t1;
# 87_470
