use us_court_cases;
SELECT disposition_or_status, status_as_of_date FROM us_court_cases.ca_saac_case_info GROUP BY(status_as_of_date);

UPDATE us_court_cases.ca_saac_case_info
SET `disposition_or_status` = replace(disposition_or_status, 'Closed', 'Active')
WHERE disposition_or_status = 'Closed';

UPDATE us_court_cases.ca_saac_case_info
SET status_as_of_date = disposition_or_status
WHERE status_as_of_date IS NULL;

UPDATE us_court_cases.ca_saac_case_info
SET disposition_or_status = REPLACE(disposition_or_status, disposition_or_status, 'Closed')
WHERE status_as_of_date LIKE '%fully briefed%'