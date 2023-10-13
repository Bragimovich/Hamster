#= create =============================================================================================================#

create table tmp_ct_1nf LIKE usa_raw.ct_higher_education_salaries;

alter table tmp_ct_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_ct_1nf;

INSERT INTO tmp_ct_1nf
SELECT *
FROM usa_raw.ct_higher_education_salaries;

alter table tmp_ct_1nf
    drop column run_id,
    drop column created_by,
    drop column created_at,
    drop column updated_at,
    drop column scrape_frequency,
    drop column last_scrape_date,
    drop column next_scrape_date,
    drop column expected_scrape_frequency,
    drop column touched_run_id,
    drop column deleted,
    drop column md5_hash;


select count(*) total_rows
from tmp_ct_1nf;
#= 900_826

#= employees ==========================================================================================================#

update tmp_ct_1nf
set md5_employee = MD5(CONCAT_WS('+', `name`, ifnull(first_name, ''), ifnull(middle_name, ''), last_name,
                                 data_source_url));

select count(*)
from tmp_ct_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;

select count(distinct t1.md5_employee) total_employee
from tmp_ct_1nf t1;
#= 101_222

insert ignore into pess_employees (raw_employee_md5_hash)
select distinct t1.md5_employee
from tmp_ct_1nf t1;

update tmp_ct_1nf
set employee_id = null;

update tmp_ct_1nf t1
    left join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;

select e1.raw_employee_md5_hash, t2.name, c1.name_clean
from pess_employees e1
         join (select t1.md5_employee, t1.name, t1.data_source_url from tmp_ct_1nf t1 group by t1.md5_employee) t2
              on e1.raw_employee_md5_hash = t2.md5_employee
         join usa_raw.ct_higher_education_salaries__names_clean c1 on t2.name = c1.name;
order by t2.name;
group by c1.name
having count(*) > 1;

update pess_employees e1
    join (select t1.md5_employee, t1.name, t1.data_source_url from tmp_ct_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
    join usa_raw.ct_higher_education_salaries__names_clean c1 on t2.name = c1.name
set e1.cleaned         = 1,
    e1.full_name       = c1.name_clean,
    e1.data_source_url = t2.data_source_url;

update pess_employees e1
    join (select t1.md5_employee, t1.name, t1.data_source_url from tmp_ct_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
set e1.state      = 'CT',
    e1.dataset_id = 5;

#= job_titles =========================================================================================================#

select job_title, count(*) as count
from tmp_ct_1nf
group by job_title
order by job_title asc;
order by count
desc;

select distinct job_title
from tmp_ct_1nf
where job_title <> '';
#= 3060

select count(distinct t1.job_title)
from tmp_ct_1nf t1
         join pess_job_titles j1
              on t1.job_title = j1.raw_job_title;
#= 38

insert ignore into pess_job_titles (raw_job_title)
select distinct job_title
from tmp_ct_1nf
where job_title <> '';
#= 5516 + (3085 - 167) = 8434
#= 8434 + (3060 - 38) = 11456

update tmp_ct_1nf t1
    left join pess_job_titles j1
    on t1.job_title = j1.raw_job_title
set t1.job_title_id = j1.id;

select j1.raw_job_title, j1.cleaned, c1.job_title_clean, c1.job_title
from pess_job_titles j1
         join usa_raw.ct_higher_education_salaries__job_title_clean c1
              on j1.raw_job_title = c1.job_title
where not j1.cleaned <=> 1;

update pess_job_titles j1
    join usa_raw.ct_higher_education_salaries__job_title_clean c1
    on j1.raw_job_title = c1.job_title
set j1.job_title = c1.job_title_clean,
    j1.cleaned   = 1
where not j1.cleaned <=> 1;

#= agencies ===========================================================================================================#

CREATE TABLE IF NOT EXISTS usa_raw.ct_higher_education_salaries__agencies
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `agency`          VARCHAR(255) NULL,
    `is_higher_ed`    BOOLEAN      NULL,
    `agency_clean`    VARCHAR(255) NULL,
    `data_source_url` varchar(255) null,
    `created_by`      VARCHAR(255)          DEFAULT 'Alim l.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

insert into usa_raw.ct_higher_education_salaries__agencies (agency, is_higher_ed, data_source_url)
select distinct agency, 0, data_source_url
from tmp_ct_1nf
order by agency asc;

update tmp_ct_1nf t1
    join usa_raw.ct_higher_education_salaries__agencies a1
    on t1.agency = a1.agency
set t1.is_higher_ed = a1.is_higher_ed;

select count(distinct t1.agency) common_agencies
from tmp_ct_1nf t1
         join pess_agencies a1
              on t1.agency = a1.raw_agency_name; # 0

update tmp_ct_1nf t1
set t1.md5_agency = MD5(CONCAT_WS('+', agency, data_source_url))
where t1.is_higher_ed = false;

select count(distinct t1.md5_agency)
from tmp_ct_1nf t1; # 87

select count(*)
from tmp_ct_1nf t1
where t1.md5_agency is not null;

select count(distinct agency)
from tmp_ct_1nf t1
where t1.is_higher_ed = false; # 68

update tmp_ct_1nf
set md5_agency = null;

ALTER TABLE pess_agencies
    AUTO_INCREMENT = 885;

insert ignore into pess_agencies (raw_agency_md5_hash)
select distinct t1.md5_agency
from tmp_ct_1nf t1
where t1.md5_agency is not null;

update tmp_ct_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;

update pess_agencies a1
    join (select t1.md5_agency, t1.agency, t1.data_source_url
          from tmp_ct_1nf t1
          where t1.md5_agency is not null
          group by t1.md5_agency) t2
    on a1.raw_agency_md5_hash = t2.md5_agency
set a1.raw_agency_name = t2.agency,
    a1.cleaned         = 0,
    a1.dataset_id      = 5,
    a1.data_source_url = t2.data_source_url;

#= employee_work_years ================================================================================================#

update tmp_ct_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '',
                            job_title_id, 5, id, data_source_url))
where md5_agency is not null;

insert into pess_employee_work_years (md5_hash)
select distinct t1.md5_ewy
from tmp_ct_1nf t1
where t1.md5_ewy is not null;

update tmp_ct_1nf
set ewy_id = null;

select t1.md5_ewy, count(*) c
from tmp_ct_1nf t1
group by t1.md5_ewy
having c > 1;

explain
update tmp_ct_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;

explain
update pess_employee_work_years e1
    join tmp_ct_1nf t1
    on e1.md5_hash = t1.md5_ewy
set e1.employee_id                 = t1.employee_id,
    e1.agency_id                   = t1.agency_id,
    e1.year                        = t1.year,
    e1.pay_type                    = 'Salary',
    e1.job_title_id                = t1.job_title_id,
    e1.raw_dataset_table_id        = 5,
    e1.raw_dataset_table_id_raw_id = t1.id,
    e1.data_source_url             = t1.data_source_url;

#= 638_416

#= compensations ======================================================================================================#

update tmp_ct_1nf
set comp_id = null;

update tmp_ct_1nf
set md5_comp = null;

update tmp_ct_1nf
set md5_comp = MD5(CONCAT_WS('+', ewy_id, 2, ``.ytd_gross, '', 1, ''))
where ytd_gross is not null;

insert into pess_compensations (md5_hash)
select distinct t1.md5_comp
from tmp_ct_1nf t1
where t1.md5_comp is not null;

update tmp_ct_1nf t1
    join pess_compensations c1 on
        t1.md5_comp = c1.md5_hash
set t1.comp_id = c1.id;

explain
update pess_compensations c1
    join tmp_ct_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.employee_work_year_id = t1.ewy_id,
    c1.compensation_type_id  = 2,
    c1.value                 = t1.ytd_gross,
    c1.is_total_compensation = 1;

update pess_compensations c1
    join tmp_ct_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.data_source_url = t1.data_source_url;

#= addresses ==========================================================================================================#

select MD5(CONCAT_WS('+', ifnull(location, ''), ifnull(street_address, ''), ifnull(county, ''), ifnull(city, ''),
                     ifnull(state_for_matching, ''), ifnull(zip, ''))) as md5_address
from tmp_ct_1nf t1
         join il_raw.il_gov_employee_salaries__locations_matched i1
              on t1.id = i1.employee_id;

update tmp_ct_1nf t1
    join il_raw.il_gov_employee_salaries__locations_matched i1
    on t1.id = i1.employee_id
set t1.md5_address = MD5(CONCAT_WS('+', ifnull(location, ''), ifnull(street_address, ''), ifnull(county, ''),
                                   ifnull(city, ''),
                                   ifnull(state_for_matching, ''), ifnull(zip, '')));

insert into pess_addresses (raw_address_md5_hash)
select distinct t1.md5_address
from tmp_ct_1nf t1
where t1.md5_address is not null;

update tmp_ct_1nf t1
    join pess_addresses a1 on
        t1.md5_address = a1.raw_address_md5_hash
set t1.address_id = a1.id;

select *
from pess_addresses a1
         join (select t1.md5_address, t1.id, t1.data_source_url from tmp_ct_1nf t1 group by t1.md5_address) t2
              on a1.raw_address_md5_hash = t2.md5_address
         join il_raw.il_gov_employee_salaries__locations_matched i1 on t2.id = i1.employee_id;

update pess_addresses a1
    join (select t1.md5_address, t1.id, t1.data_source_url from tmp_ct_1nf t1 group by t1.md5_address) t2
    on a1.raw_address_md5_hash = t2.md5_address
    join il_raw.il_gov_employee_salaries__locations_matched i1 on t2.id = i1.employee_id
set a1.street_address = i1.street_address,
    a1.county         = i1.county,
    a1.city           = ifnull(i1.city_for_matching, i1.city),
    a1.state          = 'IL',
    a1.zip            = ifnull(i1.zip5, i1.zip);

#= agency_locations ===================================================================================================#

select distinct t1.address_id, t1.agency_id
from tmp_ct_1nf t1
where t1.address_id is not null;

insert into pess_agency_locations (address_id, agency_id, data_source_url)
select distinct t1.address_id, t1.agency_id, t1.data_source_url
from tmp_ct_1nf t1
where t1.address_id is not null;

update tmp_ct_1nf t1
    join pess_agency_locations a1
    on t1.address_id = a1.address_id and t1.agency_id = a1.agency_id
set t1.agency_locations_id = a1.id;

#= employee_work_years ================================================================================================#

select distinct t1.employee_id, t1.agency_locations_id, t1.year
from tmp_ct_1nf t1
where t1.agency_locations_id is not null;

insert into pess_employees_to_locations (employee_id, location_id, isolated_known_date, data_source_url)
select distinct t1.employee_id, t1.agency_locations_id, t1.year, t1.data_source_url
from tmp_ct_1nf t1
where t1.address_id is not null;

update tmp_ct_1nf t1
    join pess_employees_to_locations e1
    on t1.employee_id = e1.employee_id and t1.agency_locations_id = e1.location_id and t1.year = e1.isolated_known_date
set t1.etl_id = e1.id;

select etl_id, count(etl_id) as c
from tmp_ct_1nf
group by etl_id
having c > 1;

select e1.id
from pess_employee_work_years e1
         join tmp_ct_1nf t1
              on e1.year = t1.year and e1.employee_id = t1.employee_id and e1.agency_id = t1.agency_id and
                 e1.job_title_id <=> t1.job_title_id
where t1.etl_id is not null;

update pess_employee_work_years e1
    join tmp_ct_1nf t1
    on e1.year = t1.year and e1.employee_id = t1.employee_id and e1.agency_id = t1.agency_id and
       e1.job_title_id <=> t1.job_title_id
set e1.employee_to_location_id = t1.etl_id,
    e1.location_id             = t1.agency_locations_id
where t1.etl_id is not null;