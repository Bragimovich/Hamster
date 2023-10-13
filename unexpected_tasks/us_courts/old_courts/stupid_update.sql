UPDATE us_courts.us_case_info
SET deleted =1
WHERE court_id>79 and court_id<100 and md5_hash not in (SELECT md5_hash from us_court_cases.old_court_case_info);


UPDATE us_courts.us_case_party
SET deleted =1
WHERE court_id>79 and court_id<100 and md5_hash not in (SELECT md5_hash from us_court_cases.old_court_case_party);

UPDATE us_courts.us_case_activities
SET deleted =1
WHERE court_id>79 and court_id<100 and md5_hash not in (SELECT md5_hash from us_court_cases.old_court_case_activities);


UPDATE us_courts.us_case_info
SET deleted =1
WHERE court_id>100 and court_id<105 and md5_hash not in (SELECT md5_hash from us_court_cases.old_court_case_info);


UPDATE us_courts.us_case_party
SET deleted =1
WHERE court_id>100 and court_id<105 and md5_hash not in (SELECT md5_hash from us_court_cases.old_court_case_party);

UPDATE us_courts.us_case_activities
SET deleted =1
WHERE court_id>100 and court_id<105 and md5_hash not in (SELECT md5_hash from us_court_cases.old_court_case_activities);

UPDATE us_courts.us_case_info
SET deleted =0
WHERE created_by='Rylan Klatt';

UPDATE us_courts.us_case_party
SET deleted =0
WHERE created_by='Rylan Klatt';

UPDATE us_courts.us_case_activities
SET deleted =0
WHERE created_by='Rylan Klatt';



UPDATE us_courts.us_case_activities
SET deleted =1
WHERE court_id=71 and md5_hash not in (SELECT md5_hash from us_court_cases.de_case_activities)


UPDATE us_courts.us_case_activities
SET deleted =1
WHERE court_id=72 and md5_hash not in (SELECT md5_hash from us_court_cases.ccomc_case_activities)



