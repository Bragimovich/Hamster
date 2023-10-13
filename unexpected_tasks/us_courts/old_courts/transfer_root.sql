INSERT IGNORE INTO us_courts.us_case_info (court_id, case_id, case_name, case_filed_date, case_type, case_description, disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash)
SELECT court_id, case_id, case_name, case_filed_date, case_type,case_description,  disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash FROM us_court_cases.old_court_case_info where deleted=0 and court_id in (90, 91, 93);


INSERT IGNORE INTO us_courts.us_case_activities (court_id, case_id, activity_date, activity_decs, activity_type, activity_pdf, data_source_url, created_by, md5_hash)
SELECT court_id, case_id, activity_date, activity_decs, activity_type, activity_pdf, data_source_url, created_by, md5_hash from us_court_cases.old_court_case_activities where  deleted=0 and court_id in (90, 91, 93);


INSERT IGNORE INTO us_courts.us_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_law_firm, party_address, party_city, party_state, party_zip, party_description, data_source_url, created_by,  md5_hash)
SELECT court_id, case_id, is_lawyer, party_name, party_type, law_firm, party_address, party_city, party_state, party_zip, party_description, data_source_url, created_by, md5_hash from us_court_cases.old_court_case_party where deleted=0 and court_id in ( 90, 91, 93);


INSERT IGNORE INTO us_courts.us_case_judgment (court_id, case_id, complaint_id, party_name, fee_amount, requested_amount, case_type, judgment_amount, judgment_date, data_source_url, created_by, md5_hash)
SELECT court_id, case_id, complaint_id, party_name, fee_amount, requested_amount, case_type, judgment_amount, judgment_date, data_source_url, created_by, md5_hash FROM us_court_cases.old_court_case_judgment where deleted=0 and court_id in (90, 91, 93);




SELECT court_id, count(IF(deleted=0, 1, NULL)), count(*) from us_case_info
group by court_id order by court_id;


INSERT IGNORE INTO us_courts.us_case_info (court_id, case_id, case_name, case_filed_date, case_type, case_description, disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash)
SELECT court_id, case_id, case_name, case_filed_date, case_type,case_description,  disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash FROM us_court_cases.de_case_info where deleted=0;


INSERT IGNORE INTO us_courts.us_case_activities (court_id, case_id, activity_date, activity_decs, activity_type, activity_pdf, data_source_url, created_by, md5_hash)
SELECT court_id, case_id, activity_date, activity_decs, activity_type, activity_pdf, data_source_url, created_by, md5_hash from us_court_cases.de_case_activities where  deleted=0 and court_id in (71,72,90, 91, 93);


INSERT IGNORE INTO us_courts.us_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_law_firm, party_address, party_city, party_state, party_zip, party_description, data_source_url, created_by,  md5_hash)
SELECT court_id, case_id, is_lawyer, party_name, party_type, law_firm, party_address, party_city, party_state, party_zip, party_description, data_source_url, created_by, md5_hash from us_court_cases.de_case_party where deleted=0


INSERT IGNORE INTO us_courts.us_case_pdfs_on_aws (court_id, case_id, source_type, aws_link, source_link, data_source_url, created_by, md5_hash )
SELECT court_id, case_id, source_type, aws_link, source_link, data_source_url, created_by, md5_hash FROM us_court_cases.de_case_pdfs_on_aws where deleted=0;
