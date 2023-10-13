SELECT c.id court_id, c.name court_name, a.case_id, c2.name, a.date, a.description activity_description,
       a.type activity_type, a.pdf activity_pdf, c2.summary_pdf, c2.raw_type
from us_courts_staging.activities a
         join us_courts_staging.cases c2 on c2.id = a.case_id
         join us_courts_staging.courts c on c.id = c2.court_id
where a.description like '%$%'






SELECT
    court_id, court_name,
    case_id,status, name,
    activity_date, activity_description, activity_type,
    activity_pdf, summary_pdf, raw_type, data_source_url
FROM
    (
        SELECT *,
               @rn := IF(@prev = court_id, @rn + 1, 1) AS rn,
               @prev := court_id
        FROM (SELECT
                           c.id court_id, c.name court_name, a.case_id, c2.name, c2.status, a.date activity_date, a.description activity_description,
                           a.type activity_type, a.pdf activity_pdf, c2.summary_pdf, c2.raw_type, c2.data_source_url
                       FROM us_courts_staging.activities a
                                join us_courts_staging.cases c2 on c2.id = a.case_id
                                join us_courts_staging.courts c on c.id = c2.court_id
              where a.description like '%$%' and c.sub_type not in ('Court of Appeals', 'Supreme Court')
                    and c2.status !='Active'
              ORDER BY c2.court_id) act
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars

    ) AS T1
WHERE rn <= 100