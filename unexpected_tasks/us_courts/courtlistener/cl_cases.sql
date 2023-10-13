select c.court_id, cc.date_filed,d.date_filed, d.case_name, d.case_name_full, cc.case_name,  cc.judges, docket_number, cc.nature_of_suit, appellate_fee_status, jury_demand, jurisdiction_type
FROM us_courts.cl_csv_dockets d
JOIN us_courts.cl_courts_clean c on c.cl_court_id=d.court_id and c.court_id is not null
JOIN us_courts.cl_csv_clusters cc on cc.docket_id = d.id
WHERE cc.date_filed>'2020-01-01'
;


DELETE o FROM cl_csv_opinions o
                  JOIN cl_csv_clusters ccc on o.cluster_id = ccc.id
WHERE ccc.date_filed <'1967-01-01' and ccc.date_filed > '1960-01-01';




INSERT IGNORE INTO us_court_cases.cl_case_info (court_id, cl_court_id, case_filed_date, raw_case_id, judge_name, case_name, case_description, case_type, created_by, data_source_url, docket_id, claster_id,
                                                md5_hash)
SELECT c.court_id, c.cl_court_id, cc.date_filed, docket_number, cc.judges, cc.case_name, d.case_name_full, cc.nature_of_suit, 'Maxim G', 'https://www.courtlistener.com/docket/' + d.id + '/' + d.slug + '/' , d.id, cc.id,
       md5(concat_ws('',c.court_id, c.cl_court_id, cc.date_filed, docket_number, cc.judges, cc.case_name, d.case_name_full, 'Maxim G'))
FROM us_courts.cl_csv_dockets d
JOIN us_courts.cl_courts_clean c on c.cl_court_id=d.court_id and c.court_id is not null
JOIN us_courts.cl_csv_clusters cc on cc.docket_id = d.id;


INSERT IGNORE INTO us_court_cases.cl_case_info (court_id, cl_court_id, raw_case_id, case_description, created_by, md5_hash)
SELECT c.court_id, c.cl_court_id,  docket_number, d.case_name_full, 'Maxim G',
       md5(concat_ws('',c.court_id, c.cl_court_id,  docket_number, d.case_name_full, 'Maxim G'))
FROM us_courts.cl_csv_dockets d
         JOIN us_courts.cl_courts_clean c on c.cl_court_id=d.court_id and c.court_id is not null;

UPDATE us_court_cases.cl_case_info i
join us_courts.cl_csv_dockets d on d.docket_number = i.raw_case_id and d.court_id=i.cl_court_id
SET i.docket_id = d.id


INSERT INTO us_court_cases.cl_case_info (court_id, cl_court_id, raw_case_id, case_id, case_name, case_filed_date, case_type, case_description, disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, created_at, updated_at, md5_hash, deleted, run_id, touched_run_id, docket_id, claster_id)
SELECT court_id, cl_court_id, raw_case_id, TRIM(SUBSTRING_INDEX(raw_case_id, ',', -1)), case_name, case_filed_date, case_type, case_description, disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, created_at, updated_at,
       md5(concat_ws('',court_id, cl_court_id, raw_case_id, TRIM(SUBSTRING_INDEX(raw_case_id, ',', -1)), case_name, case_filed_date, case_type, case_description, disposition_or_status, status_as_of_date, judge_name, data_source_url, 'Maxim G'))
        , deleted, run_id, touched_run_id, docket_id, claster_id
FROM us_court_cases.cl_case_info
WHERE raw_case_id like '%,%' and raw_case_id not like '[%' and raw_case_id not like '(%' ;



UPDATE us_court_cases.cl_case_info
SET case_id = TRIM(SUBSTRING_INDEX(raw_case_id, 'No.', -1))
where raw_case_id like 'No.%' and case_id is null;

UPDATE us_court_cases.cl_case_info
SET case_id = TRIM(SUBSTRING_INDEX(raw_case_id, 'Nos.', -1))
where raw_case_id like 'Nos.%' and case_id is null;

Delete from us_court_cases.cl_case_info
WHERE raw_case_id='';


UPDATE us_court_cases.cl_case_info
SET case_id = TRIM(raw_case_id)
where case_id is null;