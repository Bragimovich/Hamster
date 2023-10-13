set @common_source = convert('https://www.azcentral.com/pages/interactives/arizona-data/salary-individual/' using utf8mb4) collate utf8mb4_unicode_520_ci;

/* insert dataset */
insert into pess_raw_datasets
  (raw_dataset_location, raw_dataset_prefix, data_source_name, data_gather_method, data_source_url)
  select 'db01.usa_raw', 'az_public_employee_salary%', 'The Arizona Republic''s salary database', 'Scrape', @common_source
  where not exists (
    select *
    from pess_raw_datasets
    where raw_dataset_location = 'db01.usa_raw'
      and raw_dataset_prefix = 'az_public_employee_salary%'
      and data_source_name = 'The Arizona Republic''s salary database'
      and data_gather_method = 'Scrape'
      and data_source_url = @common_source
  );

set @dataset_id = (
  select id
  from pess_raw_datasets
  where raw_dataset_location = 'db01.usa_raw'
    and raw_dataset_prefix = 'az_public_employee_salary%'
    and data_source_name = 'The Arizona Republic''s salary database'
    and data_gather_method = 'Scrape'
    and data_source_url = @common_source
);

/* insert dataset table */
insert into pess_raw_dataset_tables
  (table_name, raw_dataset_id)
  select 'az_public_employee_salary', @dataset_id
  where not exists (
    select *
    from pess_raw_dataset_tables
    where table_name = 'az_public_employee_salary'
      and raw_dataset_id = @dataset_id
  );

set @dataset_table_id = (
  select id
  from pess_raw_dataset_tables
  where table_name = 'az_public_employee_salary'
    and raw_dataset_id = @dataset_id
);

/* prepare the temporary table, run below queries only when need to restart */
drop table if exists tmp_az_1nf;
create table tmp_az_1nf LIKE usa_raw.az_public_employee_salary;
alter table tmp_az_1nf convert to character set utf8mb4 collate utf8mb4_unicode_520_ci;

alter table tmp_az_1nf
  drop column department,
  drop column department_state_clear,
  drop column hire_date,
  drop column created_at,
  drop column updated_at,
  drop column scrape_dev_name,
  drop column scrape_frequency,
  drop column notes_on_annual_pay,
  drop column notes_on_hourly_rate,
  drop column other_notes,
  drop column last_scrape_date,
  drop column next_scrape_date,
  drop column expected_scrape_frequency,
  drop column dataset_name_prefix,
  drop column scrape_status,
  drop column pl_gather_task_id,
  add column employee_id bigint after year,
  add column employee_md5 varchar(255) after last_name,
  add column agency_id bigint after employer,
  add column agency_clean varchar(255) after agency_id,
  add column agency_md5 varchar(255) after agency_clean,
  add column job_title_id bigint after job_title,
  add column job_title_clean varchar(255) after job_title_id;

/* copy salaries table by filtering out higher ed. agencies */
insert into tmp_az_1nf
  (
    id,
    year,
    full_name,
    first_name,
    middle_name,
    last_name,
    employee_md5,
    employer,
    agency_md5,
    job_title,
    full_time_or_part_time,
    annual_pay,
    hourly_rate,
    overtime,
    data_source_url
  )
  select * from (
    select
      id,
      year,
      full_name,
      first_name,
      middle_name,
      last_name,
      md5(concat_ws('+', full_name, @common_source)) as employee_md5,
      employer,
      md5(concat_ws('+', employer, @common_source)) as agency_md5,
      job_title,
      full_time_or_part_time,
      annual_pay,
      hourly_rate,
      overtime,
      data_source_url
    from usa_raw.az_public_employee_salary
    where employer not regexp('school|academy|institute|college|univers')
  ) as aes
  on duplicate key update
    year = aes.year,
    full_name = aes.full_name,
    first_name = aes.first_name,
    middle_name = aes.middle_name,
    last_name = aes.last_name,
    employee_md5 = aes.employee_md5,
    employer = aes.employer,
    agency_md5 = aes.agency_md5,
    job_title = aes.job_title,
    full_time_or_part_time = aes.full_time_or_part_time,
    annual_pay = aes.annual_pay,
    hourly_rate = aes.hourly_rate,
    overtime = aes.overtime,
    data_source_url = aes.data_source_url;

/* insert agencies */
insert ignore into pess_agencies
  (raw_agency_md5_hash, raw_agency_name, cleaned, agency_name, dataset_id, data_source_url)
  select
    md5(concat_ws('+', sal.employer, @common_source)),
    sal.employer,
    true,
    sal.employer,
    @dataset_table_id,
    @common_source
  from (select distinct(employer) as employer from tmp_az_1nf where employer is not null) as sal;

/* insert job titles */
insert into pess_job_titles
  (raw_job_title, cleaned, job_title)
  select
    sal.job_title,
    if(c_jt.id is null, false, true),
    c_jt.job_title_clean
  from (select distinct(job_title) as job_title from tmp_az_1nf where job_title is not null) as sal
  left join usa_raw.az_public_employee_salary_jobs_clean as c_jt
    on sal.job_title = c_jt.job_title
  on duplicate key update
    cleaned = if(c_jt.id is null, false, true),
    job_title = c_jt.job_title_clean;

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
    null,
    sal.full_name,
    sal.first_name,
    sal.middle_name,
    sal.last_name,
    null,
    null,
    null,
    'AZ',
    @dataset_table_id,
    @common_source
  from (
    select
      md5(concat_ws('+', full_name, @common_source)) as md5_hash,
      full_name,
      first_name,
      middle_name,
      last_name
    from tmp_az_1nf
    where full_name is not null
  ) as sal
  on duplicate key update
    full_name = sal.full_name,
    first_name = sal.first_name,
    middle_name = sal.middle_name,
    last_name = sal.last_name,
    state = 'AR',
    dataset_id = @dataset_table_id;

/* fill id columns in temp table */
insert into tmp_az_1nf
  (
    id,
    employee_id,
    full_name,
    first_name,
    middle_name,
    last_name,
    agency_id,
    agency_clean,
    job_title_id,
    job_title_clean
  )
  select
    ti1.id,
    emp.id,
    emp.full_name,
    emp.first_name,
    emp.middle_name,
    emp.last_name,
    agcy.id,
    agcy.agency_name,
    jt.id,
    jt.job_title
  from tmp_az_1nf as ti1
  left join (
    select id, raw_employee_md5_hash, full_name, first_name, middle_name, last_name
    from pess_employees
    where data_source_url=@common_source
  ) as emp on emp.raw_employee_md5_hash = ti1.employee_md5
  left join (
    select id, raw_agency_md5_hash, agency_name
    from pess_agencies
    where data_source_url=@common_source
  ) as agcy on agcy.raw_agency_md5_hash = ti1.agency_md5
  left join pess_job_titles as jt on jt.raw_job_title = ti1.job_title
  on duplicate key update
    employee_id = emp.id,
    full_name = emp.full_name,
    first_name = emp.first_name,
    middle_name = emp.middle_name,
    last_name = emp.last_name,
    agency_id = agcy.id,
    agency_clean = agcy.agency_name,
    job_title_id = jt.id,
    job_title_clean = jt.job_title;

/* insert employee_work_years */
insert ignore into pess_employee_work_years
  (
    md5_hash,
    employee_id,
    employee_to_location_id,
    location_id,
    agency_id,
    year,
    full_or_part_status,
    pay_type,
    hourly_rate,
    job_title_id,
    raw_dataset_table_id,
    raw_dataset_table_id_raw_id,
    data_source_url
  )
  select
    md5(concat_ws(
      '+',
      ifnull(employee_id, ''),
      ifnull(agency_id, ''),
      ifnull(job_title_id, ''),
      ifnull(year, ''),
      ifnull(full_time_or_part_time, ''),
      ifnull(hourly_rate, ''),
      @common_source
    )),
    employee_id,
    null,
    null,
    agency_id,
    year,
    full_time_or_part_time,
    'Salary',
    hourly_rate,
    job_title_id,
    @dataset_table_id,
    max(id),
    @common_source
  from tmp_az_1nf
  group by employee_id, agency_id, job_title_id, year, full_time_or_part_time, hourly_rate;

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

insert into pess_compensation_types
  (raw_compensation_type, cleaned, compensation_type)
  select 'Overtime Pay', 0, 'Overtime Pay'
  where not exists (
    select * from pess_compensation_types where raw_compensation_type = 'Overtime Pay'
  );

set @overtime_pay_type_id = (
  select id from pess_compensation_types where raw_compensation_type = 'Overtime Pay'
);

/* insert compensations */
insert into pess_compensations
  (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url)
  select
    md5(concat_ws('+', ifnull(ewy.id, ''), @annual_salary_type_id)),
    ewy.id,
    @annual_salary_type_id,
    sal.annual_pay,
    1,
    @dataset_table_id,
    @common_source
  from (
    select
      md5(concat_ws(
        '+',
        ifnull(employee_id, ''),
        ifnull(agency_id, ''),
        ifnull(job_title_id, ''),
        ifnull(year, ''),
        ifnull(full_time_or_part_time, ''),
        ifnull(hourly_rate, ''),
        @common_source
      )) as ewy_md5,
      annual_pay
    from tmp_az_1nf
    where annual_pay is not null
      and annual_pay <> 0
  ) as sal
  left join (
    select *
    from pess_employee_work_years
    where data_source_url=@common_source
  ) as ewy on ewy.md5_hash = sal.ewy_md5
  on duplicate key update
    value = sal.annual_pay,
    is_total_compensation = 1,
    dataset_id = @dataset_table_id;

insert into pess_compensations
  (md5_hash, employee_work_year_id, compensation_type_id, value, is_total_compensation, dataset_id, data_source_url)
  select
    md5(concat_ws('+', ifnull(ewy.id, ''), @overtime_pay_type_id)),
    ewy.id,
    @overtime_pay_type_id,
    sal.overtime,
    0,
    @dataset_table_id,
    @common_source
  from (
    select
      md5(concat_ws(
        '+',
        ifnull(employee_id, ''),
        ifnull(agency_id, ''),
        ifnull(job_title_id, ''),
        ifnull(year, ''),
        ifnull(full_time_or_part_time, ''),
        ifnull(hourly_rate, ''),
        @common_source
      )) as ewy_md5,
      overtime
    from tmp_az_1nf
    where overtime is not null
      and overtime <> 0
  ) as sal
  left join (
    select *
    from pess_employee_work_years
    where data_source_url=@common_source
  ) as ewy on ewy.md5_hash = sal.ewy_md5
  on duplicate key update
    value = sal.overtime,
    is_total_compensation = 0,
    dataset_id = @dataset_table_id;
