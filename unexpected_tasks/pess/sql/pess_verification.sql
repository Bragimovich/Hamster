
select distinct data_source_url
from pess_employees;

select distinct state
from pess_employees;

select distinct agency
from usa_raw.ct_higher_education_salaries;

SELECT distinct pewy.raw_dataset_table_id,
                count(*)
FROM public_employees_salaries_staging.pess_compensations pc
         left join public_employees_salaries_staging.pess_employee_work_years pewy on pewy.id = pc.employee_work_year_id
         left join public_employees_salaries_staging.pess_employees pe on pe.id = pewy.employee_id
         left join public_employees_salaries_staging.pess_agencies pa on pa.id = pewy.agency_id
         left join public_employees_salaries_staging.pess_agency_locations pal on pal.agency_id = pa.id
         left join public_employees_salaries_staging.pess_addresses pa2 on pa2.id = pal.address_id
where pa2.state = 'IL'
group by pewy.raw_dataset_table_id;

SELECT DISTINCT pewy.raw_dataset_table_id,
                GROUP_CONCAT(distinct pa2.state SEPARATOR ',') AS states,
                COUNT(*)
FROM public_employees_salaries_staging.pess_compensations pc
         LEFT JOIN public_employees_salaries_staging.pess_employee_work_years pewy ON pewy.id = pc.employee_work_year_id
         LEFT JOIN public_employees_salaries_staging.pess_employees pe ON pe.id = pewy.employee_id
         LEFT JOIN public_employees_salaries_staging.pess_agencies pa ON pa.id = pewy.agency_id
         LEFT JOIN public_employees_salaries_staging.pess_agency_locations pal ON pal.agency_id = pa.id
         LEFT JOIN public_employees_salaries_staging.pess_addresses pa2 ON pa2.id = pal.address_id
GROUP BY pewy.raw_dataset_table_id;

select raw_agency_name, count(*) c, group_concat(distinct created_at) date_created
from pess_agencies
group by raw_agency_name
having c > 1;

select count(*)
from pess_employee_work_years; # 2_910_778

select count(*)
from pess_compensations; # 2_874_057

update pess_compensations c join pess_employee_work_years w on c.employee_work_year_id = w.id
set c.dataset_id = w.raw_dataset_table_id;

select count(*)
from pess_employees
where state = 'MI'; # 243_624

select count(*)
from pess_employees
where state = 'MI'
  and data_source_url <> 'https://www.mackinac.org/salaries?report=any&search=any&sort=wage2018-desc&filter=';

select count(*)
from pess_compensations
where dataset_id = 1
  and data_source_url <> 'https://www.mackinac.org/salaries?report=any&search=any&sort=wage2018-desc&filter=';

select count(*)
from pess_employees
where state = 'FL'; # 148_200

select count(*)
from pess_employees
where state = 'FL'
  and data_source_url <> 'https://salaries.myflorida.com';

select count(*)
from pess_compensations
where dataset_id = 4
  and data_source_url <> 'https://salaries.myflorida.com';

select count(*)
from pess_employees
where state = 'IL'; # 180_722

select count(*)
from pess_employees
where state = 'IL'
  and data_source_url <> 'https://illinoiscomptroller.gov/financial-data/state-expenditures/employee-salary-database';

select count(*)
from pess_compensations
where dataset_id = 3
  and data_source_url <> 'https://illinoiscomptroller.gov/financial-data/state-expenditures/employee-salary-database';

select count(*)
from pess_employees
where state = 'CT'; # 101_222

select count(*)
from pess_employees
where state = 'CT'
  and data_source_url <> 'https://openpayroll.ct.gov/#!/year/2022/secondary/UConn+-+Faculty';

select count(*)
from pess_compensations
where dataset_id = 5
  and data_source_url <> 'https://openpayroll.ct.gov/#!/year/2022/secondary/UConn+-+Faculty';