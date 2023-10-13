create or replace view agencies_cleaned_matched_to_agency_types as
select m1.agency_raw,
       m2.agency_clean,
       m2.limpar_UUID,
       if(m2.agency_clean is null, 0, 1) as cleaned,
       m3.employer_category              as agency_type,
       a.id                              as agency_type_id
from (select distinct (employer collate utf8mb4_unicode_520_ci) as agency_raw from usa_raw.michigan_public_employee_salary) m1
         left join usa_raw.michigan_public_employee_salary__agencies_cleaned_by_rylan as m2
                   on m1.agency_raw = m2.agency
         left join usa_raw.michigan_public_employee_salary_uniq_orgs as m3
                   on m2.agency = m3.employer_name collate utf8mb4_unicode_520_ci
         left join agency_types as a
                   on m3.employer_category <=> a.type;

create or replace view source_id_with_employee_md5_and_address_md5 as
select m1.id,
       (MD5(CONCAT_WS('', m1.full_name, m1.first_name, m1.middle_name, m1.last_name,
                      m1.data_source_url)))               as md5_employee,
       (MD5(CONCAT_WS('', m2.city, m2.county, m2.state))) as md5_address,
       m1.year,
       m1.employer,
       m1.job,
       m1.salary
from usa_raw.michigan_public_employee_salary m1
         left join usa_raw.michigan_public_employee_salary_uniq_orgs m2
                   on m1.employer = m2.employer_name;

CREATE TABLE IF NOT EXISTS tmp_mi_employee_salary
(
    `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
    `full_name`         VARCHAR(255)   NULL,
    `md5_employee`      VARCHAR(255)   NULL,
    `employer`          VARCHAR(255)   NULL,
    `employer_category` VARCHAR(255)   NULL,
    `md5_address`       VARCHAR(255)   NULL,
    `job`               VARCHAR(255)   NULL,
    `year`              VARCHAR(255)   NULL,
    `salary`            DECIMAL(15, 2) NULL,
    `data_source_url`   varchar(255)   null
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

insert into tmp_mi_employee_salary
select m1.id,
       m1.full_name,
       (MD5(CONCAT_WS('', m1.full_name, m1.first_name, m1.middle_name, m1.last_name,
                      m1.data_source_url)))                                as md5_employee,
       m1.employer,
       m2.employer_category,
       (MD5(CONCAT_WS('', m2.city, m2.county, m2.state, data_source_url))) as md5_address,
       m1.job,
       m1.year,
       m1.salary,
       m1.data_source_url
from usa_raw.michigan_public_employee_salary m1
         left join usa_raw.michigan_public_employee_salary_uniq_orgs m2
                   on m1.employer = m2.employer_name;


create table tmp_mi__agency
select m1.id,
       m1.agency,
       m1.agency_clean,
       m1.limpar_UUID,
       m2.employer_category as agency_type,
       a.id                 as agency_type_id
from usa_raw.michigan_public_employee_salary__agencies_cleaned_by_rylan as m1
         left join usa_raw.michigan_public_employee_salary_uniq_orgs as m2
                   on m1.agency = m2.employer_name
                       collate utf8mb4_unicode_520_ci
         left join agency_types as a
                   on m2.employer_category <=> a.type
                       collate utf8mb4_unicode_520_ci;



explain
select m1.id, m1.employer, m2.agency_clean, m2.limpar_UUID
from usa_raw.michigan_public_employee_salary m1
         left join usa_raw.michigan_public_employee_salary__agencies_cleaned_by_rylan m2
                   on m1.employer = m2.agency;

