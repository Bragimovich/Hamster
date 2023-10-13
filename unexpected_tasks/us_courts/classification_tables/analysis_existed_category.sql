select * from us_courts_staging.cases
where type='Torts' and summary_pdf is not null
limit 100;


SELECT
    court_id,
    raw_id,name,
    summary_pdf,
    filled_date,status, description, raw_type, type
FROM
    (
        SELECT
            court_id,
            raw_id,
            summary_pdf,
            name, filled_date,status, description, raw_type, type,
            @rn := IF(@prev = court_id, @rn + 1, 1) AS rn,
            @prev := court_id
        FROM us_courts_staging.cases
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where type='Torts' and summary_pdf is not null and raw_type!='Torts'
        ORDER BY court_id
    ) AS T1
WHERE rn <= 3