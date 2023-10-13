create table tmp_mi_1nf as
select distinct s1.id,
                s1.md5_employee,
                e1.full_name,
                e1.id as employee_id,
                s1.employer,
                s1.md5_address,
                a1.id as address_id,
                1     as agency_location_type,
                s1.job,
                s1.year,
                s1.salary
from source_id_with_employee_md5_and_address_md5 s1
         join employees e1
              on s1.md5_employee = e1.raw_employee_md5_hash
         join addresses a1
              on s1.md5_address = a1.raw_address_md5_hash;

alter table tmp_mi_1nf__old
    convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

update tmp_mi_1nf__old
set md5_hash_etoa = MD5(CONCAT_WS(' ', employee_id, address_id, 1, year));

update tmp_mi_1nf__old t1
    join agencies a1
    on t1.employer <=> a1.raw_agency_name
set t1.agency_id = a1.id;
#=======================================================================================================================
select t1.id, t1.address_id, t1.agency_id, a1.id
from tmp_mi_1nf__old t1
         join agency_locations a1
              on t1.address_id = a1.address_id and t1.agency_id = a1.agency_id;

update tmp_mi_1nf__old t1
    join agency_locations a1
    on t1.address_id = a1.address_id and t1.agency_id = a1.agency_id
set t1.agency_location_id = a1.id;
#=======================================================================================================================
select t1.id, t1.employee_id, t1.address_id, e1.id as employee_to_address_id, t1.year
from tmp_mi_1nf__old t1
         join employees_to_addresses e1
              on t1.employee_id = e1.employee_id and t1.address_id = e1.address_id and
                 t1.year = e1.isolated_known_date;

update tmp_mi_1nf__old t1
    left join employees_to_addresses e1
    on t1.employee_id = e1.employee_id and t1.address_id = e1.address_id and
       t1.year = e1.isolated_known_date
set t1.employee_to_address_id = e1.id;
#=======================================================================================================================
update tmp_mi_1nf__old
set employee_to_location_id = null;

select distinct t1.employee_id, t1.agency_location_id, t1.year
from tmp_mi_1nf__old t1
         join employees_to_locations e1
              on t1.employee_id = e1.employee_id and t1.agency_location_id = e1.location_id and
                 t1.year = e1.isolated_known_date;

update tmp_mi_1nf__old t1
    join employees_to_locations e1
    on t1.employee_id = e1.employee_id and t1.agency_location_id = e1.location_id and
       t1.year = e1.isolated_known_date
set t1.employee_to_location_id = e1.id;
#=======================================================================================================================
select t1.id, t1.job, j1.raw_job_title, j1.job_title, j1.id
from tmp_mi_1nf__old t1
         left join job_titles j1
                   on t1.job <=> j1.raw_job_title;

update tmp_mi_1nf__old t1
    left join job_titles j1
    on t1.job <=> j1.raw_job_title
set t1.job_title_id = j1.id;
#=======================================================================================================================
update tmp_mi_1nf__old
set md5_hash_ewy = MD5(CONCAT_WS(' ', employee_to_location_id, agency_location_id, agency_id, year, NULL, 'Salary',
                                 NULL, job_title_id, 1, id));

select MD5(CONCAT_WS(' ', t1.employee_to_location_id, t1.agency_location_id, t1.agency_id, t1.year, NULL, 'Salary',
                     NULL, t1.job_title_id, 1, id))
from tmp_mi_1nf__old t1;
#=======================================================================================================================
update tmp_mi_1nf__old
set employee_work_years_id = null;

select distinct t1.id as t_id, t1.employee_work_years_id, e1.id as e_id
from tmp_mi_1nf__old t1
         join employee_work_years e1
              on t1.md5_hash_ewy <=> e1.md5_hash;

update tmp_mi_1nf__old t1
    join employee_work_years e1
    on t1.md5_hash_ewy = e1.md5_hash
set t1.employee_work_years_id = e1.id;
#=======================================================================================================================
select employer, count(*) as count
from usa_raw.michigan_public_employee_salary
group by employer
order by count desc;