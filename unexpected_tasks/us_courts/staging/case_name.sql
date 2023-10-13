SELECT
    court_id,
    c.name court_name,
    raw_id as case_id,
    data_source_url
FROM
    (
        SELECT
            court_id,
            raw_id,
            name,
               data_source_url,
            @rn := IF(@prev = court_id, @rn + 1, 1) AS rn,
            @prev := court_id
        FROM us_courts_staging.cases
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where name is null
        ORDER BY court_id
    ) AS T1
join us_courts_staging.courts c on T1.court_id = c.id
WHERE rn <= 5
