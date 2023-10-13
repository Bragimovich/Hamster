SELECT 'us_saac_case_info', i.id, i.court_id, i.case_id, i.case_name,
       i.lower_court_id, i.lower_case_id
from us_courts.us_saac_case_info i
         join us_courts_staging.cases c on i.id = c.external_id
where i.deleted=0 and i.lower_court_id <1000;



INSERT INTO us_courts_staging.cases_appealed
    (external_table, external_id, case_id, raw_id,
     lower_court_id, lower_court_name, lower_case_id, lower_raw_id,
     data_source_url, created_by)
SELECT 'us_saac_case_info' external_table, i.id external_id, c.id case_id, i.case_id raw_id,
       courts.external_id, courts.name lower_court_name, c2.id lower_case_id, i.lower_case_id lower_raw_id,
       i.data_source_url, 'Maxim G'
from us_courts.us_saac_case_info i
        left join us_courts_staging.cases c on i.id = c.external_id and c.external_table='us_saac_case_info'
    left join us_courts_staging.courts on i.lower_court_id = courts.external_id
    left join us_courts_staging.cases c2 on i.lower_case_id = c2.raw_id and courts.id = c2.court_id
where i.deleted=0 and i.lower_court_id<1000 and c.id is not null;




SELECT court_id, lower_court_name, lower_court_id from us_courts.us_saac_case_additional_info
WHERE deleted=0 and lower_court_name is not null group by lower_court_name, court_id;