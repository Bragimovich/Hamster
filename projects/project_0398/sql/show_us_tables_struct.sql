use us_courts;
SHOW COLUMNS FROM us_saac_case_activities;
SHOW COLUMNS FROM us_saac_case_relations_info_pdf;
SHOW COLUMNS FROM us_saac_case_info;
SHOW COLUMNS FROM us_saac_case_relations_activity_pdf;
SHOW COLUMNS FROM us_saac_case_party;
SHOW COLUMNS FROM us_saac_case_pdfs_on_aws;
SHOW COLUMNS FROM us_saac_case_additional_info;

#select GROUP_CONCAT(COLUMN_NAME) from information_schema.columns where TABLE_NAME='tbl1_old' group by TABLE_NAME order by ORDINAL_POSITION
#use us_court_cases;
#select id, court_id, case_id, activity_date, activity_desc, activity_type, count(*) from ca_saac_case_activities
#group by court_id, case_id, activity_date, activity_desc, activity_type having count(*) > 1