#[x] create ============================================================================================================

CREATE TABLE tmp_oh_1nf LIKE usa_raw.oh_public_employee_salary;

alter table tmp_oh_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_oh_1nf;

alter table tmp_oh_1nf
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

alter table tmp_oh_1nf
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

select department as agency
from usa_raw.oh_public_employee_salary
where department regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc;

insert into tmp_oh_1nf (id, `year`, full_name, full_name_clean, first_name, middle_name, last_name, department,
                        job_description, gross_wages, hourly_rate, overtime_pay, data_source_url)
select o1.id,
       o1.`year`,
       o1.full_name,
       o1.full_name_clean,
       o1.first_name,
       o1.middle_name,
       o1.last_name,
       o1.department,
       o1.job_description,
       o1.gross_wages,
       o1.hourly_rate,
       o1.overtime_pay,
       o1.data_source_url
from usa_raw.oh_public_employee_salary o1;

#[x] initial data =====================================================================================================

explain usa_raw.oh_public_employee_salary;

insert into pess_raw_datasets(raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method,
                              data_source_url, created_by)
values ('db01.usa_raw', 'oh_public_employee_salary%', 'Ohio Public Employee Salary', 'Scrape',
        'http://treasurer.ohio.gov/State_Salary/', 'Alim L.');

insert into pess_raw_dataset_tables(`table_name`, raw_dataset_id, created_by)
values ('oh_public_employee_salary', 9, 'Alim L.');

insert ignore into pess_compensation_types(raw_compensation_type, cleaned, compensation_type, created_by)
values ('Gross Wages', 0, 'Gross Wages', 'Alim L.');

update tmp_oh_1nf t1
set t1.md5_employee = MD5(CONCAT_WS('+', t1.full_name, lower(t1.department), lower(t1.job_description),
                                    t1.data_source_url)); # 241_681

update tmp_oh_1nf as t1
set t1.md5_agency = MD5(CONCAT_WS('+', lower(t1.department), t1.data_source_url));
# 241_681

#[x] employees =========================================================================================================

-- checks
select distinct `year`
from tmp_oh_1nf; # 2016-2019

select count(*)
from tmp_oh_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash; # 0

select count(distinct t1.md5_employee) as total_employee
from tmp_oh_1nf t1; # 130_282 (140_001 - department, 150_003 - department+job_title)

select md5_employee, count(*) as count
from tmp_oh_1nf
group by md5_employee, `year`
having count > 1
order by count desc;

select sum(count)
from (select count(*) as count
      from tmp_oh_1nf
      group by md5_employee, `year`
      having count > 1
      order by count desc) as tmp;

select md5_employee,
       `year`,
       full_name,
       department,
       job_description,
       gross_wages,
       hourly_rate,
       overtime_pay
from tmp_oh_1nf
where md5_employee in ('3d578deab7c507c4356ee31523935c9a',
                       '6afc4f08f19dd6d6d6f903bb1642d100',
                       '74a5c8b06fa92b8d136c253a70fd0225',
                       '9e62c99e7223d1d2e54f64f373cb620b',
                       'b3e26c5ce1b89d6ea625555c34133037',
                       'ba0d0ca5a71dfc34afbb1acdc24f2838',
                       '89c22552d052b57285bfbd4f89edd85c',
                       'a51a4740dedd308434cb1df803df722e',
                       'ba4737dfad0e93413466a01857035085',
                       'e07a7a549c937674ed1248f0005edd07',
                       'f58b21cee52c1f1cd0520546c779ee5e',
                       '0000b7ceacd20b9a174dfab0fe74d5c4',
                       '4679fb5dd7b759489e148a1f54d27ed7',
                       'ba91cb3105e8da96014f2dbc5f1cb01f',
                       'd195ac9b29eb16e32e7ca12d3a08e67d',
                       'e79538890422683459594a69ad88bc09'
    )
order by md5_employee, `year`;

select t1.md5_employee,
       t1.full_name,
       (o1.full_name_clean is not null),
       o1.full_name_clean
from tmp_oh_1nf t1
         left join usa_raw.oh_public_employee_salary__names_clean o1 on t1.full_name = o1.full_name
where o1.full_name_clean is null
group by t1.md5_employee; # 0

update tmp_oh_1nf
set employee_id = null;

-- process
insert ignore into pess_employees (raw_employee_md5_hash, cleaned, full_name, first_name, middle_name, last_name,
                                   suffix, state, dataset_id, data_source_url)
select t1.md5_employee,
       (o1.full_name_clean is not null),
       o1.full_name_clean,
       ifnull(o1.first_name, ''),
       ifnull(o1.middle_name, ''),
       o1.last_name,
       ifnull(o1.suffix, ''),
       'OH',
       9,
       t1.data_source_url
from tmp_oh_1nf t1
         join usa_raw.oh_public_employee_salary__names_clean o1 on t1.full_name = o1.full_name
group by t1.md5_employee; # 150_003

update tmp_oh_1nf t1
    join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;
# 241_681

#[x] job_titles ========================================================================================================

-- checks
select t1.job_description, count(*) as count
from tmp_oh_1nf t1
group by t1.job_description
order by t1.job_description asc;
# 1_816
# order by count desc;

select count(distinct t1.job_description)
# select distinct t1.job_description
from tmp_oh_1nf t1
         join pess_job_titles j1
              on t1.job_description = j1.raw_job_title;
# 218

-- process
insert ignore into pess_job_titles (raw_job_title, cleaned, job_title)
select t1.job_description, (o1.job_description_clean is not null), o1.job_description_clean
from tmp_oh_1nf t1
         left join usa_raw.oh_public_employee_salary__job_descriptions_clean o1
                   on t1.job_description = o1.job_description
group by t1.job_description; # 1_598 = 1_816 - 218

update tmp_oh_1nf t1
    left join pess_job_titles j1
    on t1.job_description = j1.raw_job_title
set t1.job_title_id = j1.id;
# 241_681

#[x] agencies ==========================================================================================================

-- checks
select department as agency
from usa_raw.oh_public_employee_salary
where department regexp 'college|universit|academ|school|institut'
group by agency
order by agency asc; # 7 - include all

select count(distinct tmp_oh_1nf.md5_agency)
from tmp_oh_1nf;
#152

select distinct department
from tmp_oh_1nf;
# 152

-- process
insert ignore into pess_agencies (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, pl_org_id, limpar_uuid,
                                  dataset_id, data_source_url)
select t1.md5_agency,
       t1.department,
       (o1.department_uniq_clear is not null) as cleaned,
       o1.department_uniq_clear,
       o1.pl_production_org_id,
       o1.limpar_org_id,
       9,
       t1.data_source_url
from tmp_oh_1nf t1
         left join usa_raw.oh_public_employee_salary__departments o1
                   on t1.department = o1.department
group by t1.md5_agency; #152

update tmp_oh_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;
# 241_681

#[x] employee_work_years ===============================================================================================

-- checks
select distinct job_description
from tmp_oh_1nf;

select count(distinct md5_ewy)
from tmp_oh_1nf; # 241_681

select count(distinct t1.md5_ewy)
from tmp_oh_1nf t1
         join pess_employee_work_years p1 on t1.md5_ewy = p1.md5_hash;

update tmp_oh_1nf
set ewy_id = null;

-- process
update tmp_oh_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Wage', hourly_rate, job_title_id, 9, id,
                            data_source_url));

insert ignore into pess_employee_work_years(md5_hash, employee_id, agency_id, `year`, pay_type, hourly_rate,
                                            job_title_id, raw_dataset_table_id, raw_dataset_table_id_raw_id,
                                            data_source_url)
select t1.md5_ewy,
       t1.employee_id,
       t1.agency_id,
       t1.year,
       'Wage',
       t1.hourly_rate,
       t1.job_title_id,
       9,
       t1.id,
       t1.data_source_url
from tmp_oh_1nf t1
group by t1.md5_ewy; # 241_681

update tmp_oh_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;
# 241_681

update pess_employee_work_years p1
    join tmp_oh_1nf t1 on p1.md5_hash = t1.md5_ewy
set p1.hourly_rate = t1.hourly_rate
where p1.raw_dataset_table_id = 9;

#[x] compensations =====================================================================================================

-- gross_wages
update tmp_oh_1nf t1
set t1.md5_gross_wages = MD5(CONCAT_WS('+', t1.ewy_id, 22, t1.gross_wages, '', 1, '', 9, t1.data_source_url));
# 241_681

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_gross_wages, t1.ewy_id, 22, t1.gross_wages, 1, 9, t1.data_source_url
from tmp_oh_1nf t1;
# 241_681

-- overtime_pay
update tmp_oh_1nf t1
set t1.md5_overtime_pay = MD5(CONCAT_WS('+', t1.ewy_id, 6, t1.overtime_pay, '', 0, '', 9, t1.data_source_url))
where t1.overtime_pay <> 0;
# 115_718

insert ignore into pess_compensations (md5_hash, employee_work_year_id, compensation_type_id, `value`,
                                       is_total_compensation, dataset_id, data_source_url)
select t1.md5_overtime_pay, t1.ewy_id, 6, t1.overtime_pay, 0, 9, t1.data_source_url
from tmp_oh_1nf t1
where t1.overtime_pay <> 0;
# 115_718

select count(*)
from tmp_oh_1nf
where overtime_pay = 0; # 125_963

select count(*)
from tmp_oh_1nf
where overtime_pay <> 0; # 115_718