set @common_source = convert('https://www.ark.org/dfa/transparency/employee_compensation.php' using utf8mb4) collate utf8mb4_unicode_520_ci;

/* insert dataset */
insert into pess_raw_datasets
  (raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url)
  select 'db01.state_salaries__raw', 'ar_employee_salaries%', 'Transparency.Arkansas.gov Employee Salaries', 'Scrape', @common_source
  where not exists (
    select *
    from pess_raw_datasets
    where raw_dataset_location = 'db01.state_salaries__raw'
      and raw_dataset_prefix = 'ar_employee_salaries%'
      and data_source_name = 'Transparency.Arkansas.gov Employee Salaries'
      and data_gather_method = 'Scrape'
      and data_source_url = @common_source
  );

set @dataset_id = (
  select id
  from pess_raw_datasets
  where raw_dataset_location = 'db01.state_salaries__raw'
    and raw_dataset_prefix = 'ar_employee_salaries%'
    and data_source_name = 'Transparency.Arkansas.gov Employee Salaries'
    and data_gather_method = 'Scrape'
    and data_source_url = @common_source
);

/* insert dataset table */
insert into pess_raw_dataset_tables
  (table_name, raw_dataset_id)
  select 'ar_employee_salaries', @dataset_id
  where not exists (
    select *
    from pess_raw_dataset_tables
    where table_name = 'ar_employee_salaries'
      and raw_dataset_id = @dataset_id
  );

set @dataset_table_id = (
  select id
  from pess_raw_dataset_tables
  where table_name = 'ar_employee_salaries'
    and raw_dataset_id = @dataset_id
);

/* prepare the temporary table, run below queries only when need to restart */
drop table if exists tmp_ar_1nf;
create table tmp_ar_1nf LIKE state_salaries__raw.ar_employee_salaries;
alter table tmp_ar_1nf convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

alter table tmp_ar_1nf
  drop column run_id,
  drop column created_by,
  drop column pay_class_category,
  drop column pay_scale_type,
  drop column position_number,
  drop column extra_help_flag,
  drop column class_code,
  drop column career_service_date,
  drop column pay_grade,
  drop column percent_of_time,
  drop column created_at,
  drop column updated_at,
  drop column touched_run_id,
  drop column is_active,
  drop column deleted,
  drop column md5_hash,
  add column employee_id bigint after employee_name,
  add column full_name varchar(255) after employee_id,
  add column first_name varchar(255) after full_name,
  add column middle_name varchar(255) after first_name,
  add column last_name varchar(255) after middle_name,
  add column suffix varchar(255) after last_name,
  add column employee_md5 varchar(255) after suffix,
  add column agency_id bigint after agency,
  add column agency_clean varchar(255) after agency_id,
  add column agency_md5 varchar(255) after agency_clean,
  add column position_title_id bigint after position_title,
  add column position_title_clean varchar(255) after position_title_id;

/* copy salaries table by filtering out higher ed. agencies */
insert into tmp_ar_1nf
  (
    id,
    fiscal_year,
    agency,
    agency_md5,
    position_title,
    employee_name,
    gender,
    race,
    employee_md5,
    annual_salary,
    data_source_url
  )
  select * from (
    select
      id,
      fiscal_year,
      agency,
      md5(concat_ws('+', agency, @common_source)) as agency_md5,
      position_title,
      employee_name,
      gender,
      race,
      md5(concat_ws('+', employee_name, ifnull(race, ''), ifnull(gender, ''), @common_source)) as employee_md5,
      annual_salary,
      data_source_url
    from state_salaries__raw.ar_employee_salaries
    where deleted <> 1
      and agency not regexp('school|academy|institute|college|univers')
  ) as aes
  on duplicate key update
    fiscal_year = aes.fiscal_year,
    agency = aes.agency,
    agency_md5 = aes.agency_md5,
    position_title = aes.position_title,
    employee_name = aes.employee_name,
    gender = aes.gender,
    race = aes.race,
    employee_md5 = aes.employee_md5,
    annual_salary = aes.annual_salary,
    data_source_url = aes.data_source_url;

/* insert agencies */
insert into pess_agencies
  (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, dataset_id, data_source_url)
  select
    md5(concat_ws('+', sal.agency, @common_source)),
    sal.agency,
    if(c_agcy.id is null, false, true),
    c_agcy.agency_clean,
    @dataset_table_id,
    @common_source
  from (select distinct(agency) as agency from tmp_ar_1nf where agency is not null) as sal
  left join state_salaries__raw.ar_employee_salaries__agencies_clean as c_agcy
    on sal.agency = c_agcy.agency
  on duplicate key update
    cleaned = if(c_agcy.id is null, false, true),
    agency_name = c_agcy.agency_clean,
    dataset_id = @dataset_table_id;

/* insert job titles */
insert into pess_job_titles
  (raw_job_title, cleaned, job_title)
  select
    sal.position_title,
    if(c_jt.id is null, false, true),
    c_jt.position_title_clean
  from (select distinct(position_title) as position_title from tmp_ar_1nf where position_title is not null) as sal
  left join state_salaries__raw.ar_employee_salaries__position_titles_clean as c_jt
    on sal.position_title = c_jt.position_title
  on duplicate key update
    cleaned = if(c_jt.id is null, false, true),
    job_title = c_jt.position_title_clean;

/* insert employees */
insert into pess_employees
  (
    raw_employee_md5_hash,
    cleaned,
    full_name,
    first_name,
    middle_name,
    last_name,
    suffix,
    race,
    gender,
    state,
    dataset_id,
    data_source_url
  )
  select
    sal.md5_hash,
    if(c_name.id is null, false, true),
    c_name.employee_name_clean,
    c_name.first_name,
    c_name.middle_name,
    c_name.last_name,
    c_name.suffix,
    sal.race,
    sal.gender,
    'AR',
    @dataset_table_id,
    @common_source
  from (
    select
      md5(concat_ws('+', employee_name, ifnull(race, ''), ifnull(gender, ''), @common_source)) as md5_hash,
      employee_name,
      race,
      gender
    from tmp_ar_1nf
    where employee_name is not null
    group by employee_name, race, gender
  ) as sal
  left join state_salaries__raw.ar_employee_salaries__names_clean as c_name
    on sal.employee_name = c_name.employee_name
  on duplicate key update
    cleaned = if(c_name.id is null, false, true),
    full_name = c_name.employee_name_clean,
    first_name = c_name.first_name,
    middle_name = c_name.middle_name,
    last_name = c_name.last_name,
    suffix = c_name.suffix,
    state = 'AR',
    dataset_id = @dataset_table_id;

/* fill id columns in temp table */
insert into tmp_ar_1nf
  (
    id,
    employee_id,
    full_name,
    first_name,
    middle_name,
    last_name,
    suffix,
    agency_id,
    agency_clean,
    position_title_id,
    position_title_clean
  )
  select
    ti1.id,
    emp.id,
    emp.full_name,
    emp.first_name,
    emp.middle_name,
    emp.last_name,
    emp.suffix,
    agcy.id,
    agcy.agency_name,
    jt.id,
    jt.job_title
  from tmp_ar_1nf as ti1
  left join (
    select id, raw_employee_md5_hash, full_name, first_name, middle_name, last_name, suffix
    from pess_employees
    where data_source_url=@common_source
  ) as emp on emp.raw_employee_md5_hash = ti1.employee_md5
  left join (
    select id, raw_agency_md5_hash, agency_name
    from pess_agencies
    where data_source_url=@common_source
  ) as agcy on agcy.raw_agency_md5_hash = ti1.agency_md5
  left join pess_job_titles as jt on jt.raw_job_title = ti1.position_title
  on duplicate key update
    employee_id = emp.id,
    full_name = emp.full_name,
    first_name = emp.first_name,
    middle_name = emp.middle_name,
    last_name = emp.last_name,
    suffix = emp.suffix,
    agency_id = agcy.id,
    agency_clean = agcy.agency_name,
    position_title_id = jt.id,
    position_title_clean = jt.job_title;

/* insert employee_work_years */
insert ignore into pess_employee_work_years
  (md5_hash, employee_id, agency_id, job_title_id, year, raw_dataset_table_id, raw_dataset_table_id_raw_id, pay_type, data_source_url)
  select
    md5(concat_ws('+', ifnull(employee_id, ''), '', '', ifnull(agency_id, ''), ifnull(position_title_id, ''), ifnull(fiscal_year, ''), '', 'Salary', '', @common_source)),
    employee_id,
    agency_id,
    position_title_id,
    fiscal_year,
    @dataset_table_id,
    max(id),
    'Salary',
    @common_source
  from tmp_ar_1nf
  group by employee_id, agency_id, position_title_id, fiscal_year;

/* insert compensation type */
insert into pess_compensation_types
  (raw_compensation_type, cleaned, compensation_type)
  select 'Annual Salary', 0, 'Annual Salary'
  where not exists (
    select * from pess_compensation_types where raw_compensation_type = 'Annual Salary'
  );

set @annual_salary_type_id = (
  select id from pess_compensation_types where raw_compensation_type = 'Annual Salary'
);

/* insert compensations */
insert into pess_compensations
  (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url)
  select
    md5(concat_ws('+', ifnull(ewy.id, ''), @annual_salary_type_id)),
    ewy.id,
    @annual_salary_type_id,
    sal.annual_salary,
    1,
    @dataset_table_id,
    sal.data_source_url
  from (
    select
      md5(concat_ws('+', ifnull(employee_id, ''), '', '', ifnull(agency_id, ''), ifnull(position_title_id, ''), ifnull(fiscal_year, ''), '', 'Salary', '', @common_source)) as ewy_md5,
      annual_salary,
      data_source_url
    from tmp_ar_1nf
    where annual_salary is not null
      and annual_salary <> 0
  ) as sal
  left join (
    select *
    from pess_employee_work_years
    where data_source_url=@common_source
  ) as ewy on ewy.md5_hash = sal.ewy_md5
  on duplicate key update
    value = sal.annual_salary,
    is_total_compensation = 1,
    dataset_id = @dataset_table_id,
    data_source_url = sal.data_source_url;
