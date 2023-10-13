SELECT court_id,count(*) from us_courts.us_case_judgment
where judgment_amount_int>49999 and deleted=0;



SELECT
    court_id, court_name, case_id,case_name, data_source_url, judgment_amount,judgment_amount_int, judgment_date, case_type, status_as_of_date
FROM
    (
        SELECT
            j.court_id, uct.court_name, j.case_id, case_name, j.data_source_url, judgment_amount,judgment_amount_int, judgment_date, i.case_type, i.status_as_of_date,
            @rn := IF(@prev = j.court_id, @rn + 1, 1) AS rn,
            @prev := j.court_id
        from us_courts.us_case_judgment j
                 left join us_courts.us_courts_table uct on j.court_id = uct.court_id
                 left join us_courts.us_case_info i on j.case_id = i.case_id
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where judgment_amount_int>49999 and j.deleted=0 and i.deleted=0
        ORDER BY j.court_id
    ) AS T1
WHERE rn <= 15