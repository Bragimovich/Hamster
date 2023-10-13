select j.court_id, uct.court_name, j.case_id, case_name, j.data_source_url, judgment_amount, judgment_date, party_name
from us_courts.us_case_judgment j
         join us_courts.us_courts_table uct on j.court_id = uct.court_id
         join us_courts.us_case_info i on j.case_id = i.case_id
where judgment_amount is not null;





SELECT
    court_id, court_name, case_id,case_name, data_source_url, judgment_amount, judgment_date, party_name
FROM
    (
        SELECT
            j.court_id, uct.court_name, j.case_id, case_name, j.data_source_url, judgment_amount, judgment_date, party_name,
            @rn := IF(@prev = j.court_id, @rn + 1, 1) AS rn,
            @prev := j.court_id
        from us_courts.us_case_judgment j
                 join us_courts.us_courts_table uct on j.court_id = uct.court_id
            join us_courts.us_case_info i on j.case_id = i.case_id
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where judgment_amount is not null
        ORDER BY j.court_id
    ) AS T1
WHERE rn <= 5