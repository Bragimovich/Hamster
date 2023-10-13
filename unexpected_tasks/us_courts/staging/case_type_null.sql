
SELECT ct.id as court_id, ct.name court_name, c.name, c.raw_id, c.data_source_url, c.description, c.raw_type, c.summary_pdf, c.summary_text
from
    (
        SELECT
            raw_id,
            court_id,
            name,
            data_source_url,
            description,
            raw_type,
               summary_pdf,
               summary_text,
            @rn := IF(@prev = court_id, @rn + 1, 1) AS rn,
            @prev := court_id
        FROM us_courts_staging.cases
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where type is null
        ORDER BY court_id
    ) AS c
join us_courts_staging.courts ct on ct.id = c.court_id
WHERE rn <= 35;


