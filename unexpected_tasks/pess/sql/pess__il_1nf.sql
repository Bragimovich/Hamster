#= create =============================================================================================================#

create table tmp_il_1nf LIKE il_raw.il_gov_employee_salaries;

alter table tmp_il_1nf
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

truncate tmp_il_1nf;

insert into tmp_il_1nf
select *
from il_raw.il_gov_employee_salaries;
where id in (select employee_id from il_raw.il_gov_employee_salaries__locations_matched);

alter table tmp_il_1nf
    drop column md5,
    drop column created_by,
    drop column created_at,
    drop column scrape_frequency,
    drop column data_source,
    drop column first_name_clean,
    drop column last_name_clean,
    drop column full_name_clean;

select count(*) total_rows
from tmp_il_1nf;
#= 638_416

#= employees ==========================================================================================================#

update tmp_il_1nf
set md5_employee = MD5(CONCAT_WS('+', full_name, first_name, ifnull(middle_name, ''), last_name, data_source_url));

select count(*)
from tmp_il_1nf t1
         join pess_employees e1
              on t1.md5_employee = e1.raw_employee_md5_hash;

select count(distinct t1.md5_employee) total_employee
from tmp_il_1nf t1;
#= 180_722

insert ignore into pess_employees (raw_employee_md5_hash)
select distinct t1.md5_employee
from tmp_il_1nf t1;
#= 391_824 + 180_722

update tmp_il_1nf
set employee_id = null;

update tmp_il_1nf t1
    left join pess_employees e1
    on t1.md5_employee = e1.raw_employee_md5_hash
set t1.employee_id = e1.id;

select e1.raw_employee_md5_hash
from pess_employees e1
         join (select t1.md5_employee, t1.full_name, t1.data_source_url from tmp_il_1nf t1 group by t1.md5_employee) t2
              on e1.raw_employee_md5_hash = t2.md5_employee
         join il_raw.il_gov_employee_salaries__names_clean i1 on t2.full_name = i1.full_name;
group by i1.full_name
having count(*) > 1;

update pess_employees e1
    join (select t1.md5_employee, t1.full_name, t1.data_source_url from tmp_il_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
    join il_raw.il_gov_employee_salaries__names_clean i1 on t2.full_name = i1.full_name
set e1.cleaned         = 1,
    e1.full_name       = i1.full_name_clean,
    e1.data_source_url = t2.data_source_url;

update pess_employees e1
    join (select t1.md5_employee from tmp_il_1nf t1 group by t1.md5_employee) t2
    on e1.raw_employee_md5_hash = t2.md5_employee
set e1.state      = 'IL',
    e1.dataset_id = 3;

#= job_titles =========================================================================================================#

select position, count(*) as count
from tmp_il_1nf
group by position
order by position asc;
order by count
desc;

select distinct position
from tmp_il_1nf
where position <> '';
#= 3085

select count(distinct t1.position)
from tmp_il_1nf t1
         join pess_job_titles j1
              on t1.position = j1.raw_job_title;
#= 167

insert ignore into pess_job_titles (raw_job_title)
select distinct position
from tmp_il_1nf
where position <> '';
#= 5516 + (3085 - 167) = 8434

update tmp_il_1nf t1
    left join pess_job_titles j1
    on t1.position = j1.raw_job_title
set t1.job_title_id = j1.id;

select j1.raw_job_title, j1.cleaned, i1.clean_name, i1.position
from pess_job_titles j1
         join il_raw.il_gov_employee_salaries__clean_position_names i1
              on j1.raw_job_title = i1.position;
where i1.clean_name is not null
  and not j1.cleaned <=> 1;

update pess_job_titles j1
    join il_raw.il_gov_employee_salaries__clean_position_names i1
    on j1.raw_job_title = i1.position
set j1.job_title = i1.clean_name,
    j1.cleaned   = 1
where i1.clean_name is not null
  and not j1.cleaned <=> 1;

#= agencies ===========================================================================================================#

select distinct agency
from tmp_il_1nf
where agency <> '';
    (105)

update tmp_il_1nf t1
set t1.md5_agency = MD5(CONCAT_WS('+', agency, data_source_url))
where t1.agency is not null;

select distinct md5_agency
from tmp_il_1nf;

select distinct t.agency_id
from tmp_il_1nf t
where t.agency_id < 780;

select count(distinct t1.agency) common_agencies
from tmp_il_1nf t1
         join pess_agencies a1
              on t1.agency = a1.raw_agency_name
where a1.raw_agency_md5_hash is null; # 7

insert ignore into pess_agencies (raw_agency_name)
select distinct agency
from tmp_il_1nf;

update tmp_il_1nf t1
    left join pess_agencies a1
    on t1.md5_agency = a1.raw_agency_md5_hash
set t1.agency_id = a1.id;

update pess_agencies a1
    left join il_raw.il_gov_employee_salaries__agencies_clean i1
    on a1.raw_agency_name <=> i1.agency
set a1.agency_name = i1.agency_clean,
    a1.cleaned     = 1
where i1.agency_clean is not null
  and not a1.cleaned <=> 1;

#= employee_work_years ================================================================================================#

update tmp_il_1nf
set md5_ewy = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '',
                            ifnull(job_title_id, ''), 3, id, data_source_url))
where ytd_gross is not null;

insert into pess_employee_work_years (md5_hash)
select distinct t1.md5_ewy
from tmp_il_1nf t1
where t1.md5_ewy is not null;

update tmp_il_1nf
set ewy_id = null;

explain
update tmp_il_1nf t1
    join pess_employee_work_years e1
    on t1.md5_ewy = e1.md5_hash
set t1.ewy_id = e1.id;

explain
update pess_employee_work_years e1
    join tmp_il_1nf t1
    on e1.md5_hash = t1.md5_ewy
set e1.employee_id                 = t1.employee_id,
    e1.agency_id                   = t1.agency_id,
    e1.year                        = t1.year,
    e1.pay_type                    = 'Salary',
    e1.job_title_id                = t1.job_title_id,
    e1.raw_dataset_table_id        = 3,
    e1.raw_dataset_table_id_raw_id = t1.id,
    e1.data_source_url             = t1.data_source_url;

#= 638_416

update pess_employee_work_years e1
    join tmp_il_1nf t1
    on e1.md5_hash = t1.md5_ewy
set e1.agency_id = t1.agency_id;

update pess_employee_work_years
set md5_hash = MD5(CONCAT_WS('+', employee_id, '', '', agency_id, `year`, '', 'Salary', '',
                             ifnull(job_title_id, ''), raw_dataset_table_id, raw_dataset_table_id_raw_id,
                             data_source_url))
where raw_dataset_table_id = 3;

select count(*)
from pess_employee_work_years p
         join tmp_il_1nf t
              on p.md5_hash = t.md5_ewy;

select count(*)
from pess_employee_work_years
where raw_dataset_table_id = 3;

#= compensations ======================================================================================================#

update tmp_il_1nf
set comp_id = null;

update tmp_il_1nf
set md5_comp = null;

update tmp_il_1nf
set md5_comp = MD5(CONCAT_WS('+', ewy_id, 2, ``.ytd_gross, '', 1, ''))
where ytd_gross is not null;

insert into pess_compensations (md5_hash)
select distinct t1.md5_comp
from tmp_il_1nf t1
where t1.md5_comp is not null;

update tmp_il_1nf t1
    join pess_compensations c1 on
        t1.md5_comp = c1.md5_hash
set t1.comp_id = c1.id;

explain
update pess_compensations c1
    join tmp_il_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.employee_work_year_id = t1.ewy_id,
    c1.compensation_type_id  = 2,
    c1.value                 = t1.ytd_gross,
    c1.is_total_compensation = 1;

update pess_compensations c1
    join tmp_il_1nf t1
    on c1.md5_hash = t1.md5_comp
set c1.data_source_url = t1.data_source_url;

#= addresses ==========================================================================================================#

select MD5(CONCAT_WS('+', ifnull(location, ''), ifnull(street_address, ''), ifnull(county, ''), ifnull(city, ''),
                     ifnull(state_for_matching, ''), ifnull(zip, ''))) as md5_address
from tmp_il_1nf t1
         join il_raw.il_gov_employee_salaries__locations_matched i1
              on t1.id = i1.employee_id;

update tmp_il_1nf t1
    join il_raw.il_gov_employee_salaries__locations_matched i1
    on t1.id = i1.employee_id
set t1.md5_address = MD5(CONCAT_WS('+', ifnull(location, ''), ifnull(street_address, ''), ifnull(county, ''),
                                   ifnull(city, ''),
                                   ifnull(state_for_matching, ''), ifnull(zip, '')));

insert into pess_addresses (raw_address_md5_hash)
select distinct t1.md5_address
from tmp_il_1nf t1
where t1.md5_address is not null;

update tmp_il_1nf t1
    join pess_addresses a1 on
        t1.md5_address = a1.raw_address_md5_hash
set t1.address_id = a1.id;

select *
from pess_addresses a1
         join (select t1.md5_address, t1.id, t1.data_source_url from tmp_il_1nf t1 group by t1.md5_address) t2
              on a1.raw_address_md5_hash = t2.md5_address
         join il_raw.il_gov_employee_salaries__locations_matched i1 on t2.id = i1.employee_id;

update pess_addresses a1
    join (select t1.md5_address, t1.id, t1.data_source_url from tmp_il_1nf t1 group by t1.md5_address) t2
    on a1.raw_address_md5_hash = t2.md5_address
    join il_raw.il_gov_employee_salaries__locations_matched i1 on t2.id = i1.employee_id
set a1.street_address = i1.street_address,
    a1.county         = i1.county,
    a1.city           = ifnull(i1.city_for_matching, i1.city),
    a1.state          = 'IL',
    a1.zip            = ifnull(i1.zip5, i1.zip);

#= agency_locations ===================================================================================================#

select distinct t1.address_id, t1.agency_id
from tmp_il_1nf t1
where t1.address_id is not null;

select distinct t1.agency_id,
                t1.agency,
                group_concat(distinct t1.address_id),
                count(*)
from tmp_il_1nf t1
where t1.address_id is not null
group by t1.agency_id;

insert into pess_agency_locations (address_id, agency_id, data_source_url)
select distinct t1.address_id, t1.agency_id, t1.data_source_url
from tmp_il_1nf t1
where t1.address_id is not null;

update tmp_il_1nf t1
    join pess_agency_locations a1
    on t1.address_id = a1.address_id and t1.agency_id = a1.agency_id
set t1.agency_locations_id = a1.id;

#= employee_to_locations ==============================================================================================#

select distinct t1.employee_id, t1.agency_locations_id, t1.year
from tmp_il_1nf t1
where t1.agency_locations_id is not null;

insert into pess_employees_to_locations (employee_id, location_id, isolated_known_date, data_source_url)
select distinct t1.employee_id, t1.agency_locations_id, t1.year, t1.data_source_url
from tmp_il_1nf t1
where t1.address_id is not null;

update tmp_il_1nf t1
    join pess_employees_to_locations e1
    on t1.employee_id = e1.employee_id and t1.agency_locations_id = e1.location_id and t1.year = e1.isolated_known_date
set t1.etl_id = e1.id;

select e1.id
from pess_employee_work_years e1
         join tmp_il_1nf t1
              on e1.year = t1.year and e1.employee_id = t1.employee_id and e1.agency_id = t1.agency_id and
                 e1.job_title_id <=> t1.job_title_id
where t1.etl_id is not null;

update pess_employee_work_years e1
    join tmp_il_1nf t1
    on e1.year = t1.year and e1.employee_id = t1.employee_id and e1.agency_id = t1.agency_id and
       e1.job_title_id <=> t1.job_title_id
set e1.employee_to_location_id = t1.etl_id,
    e1.location_id             = t1.agency_locations_id
where t1.etl_id is not null;