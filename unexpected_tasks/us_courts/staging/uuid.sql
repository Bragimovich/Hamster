SELECT LOWER(CONCAT(
         HEX(RANDOM_BYTES(4)), '-',
         HEX(RANDOM_BYTES(2)), '-4',
         SUBSTR(HEX(RANDOM_BYTES(2)), 2, 3), '-',
         CONCAT(HEX(FLOOR(ASCII(RANDOM_BYTES(1)) / 64)+8),SUBSTR(HEX(RANDOM_BYTES(2)), 2, 3)), '-',
         HEX(RANDOM_BYTES(6));



UPDATE us_courts.us_saac_case_info i
    JOIN us_courts_staging.courts courts on i.court_id = courts.external_id
    JOIN us_courts_staging.cases c on i.case_id = c.raw_id and c.court_id = courts.id
SET i.generated_uuid = c.generated_uuid
WHERE i.generated_uuid is null;


UPDATE us_courts.us_case_activities
SET generated_uuid = UUID()
where generated_uuid is null;

UPDATE us_courts.us_saac_case_activities
SET generated_uuid = UUID()
where generated_uuid is null;

UPDATE us_courts_staging.activities a
    join us_courts.us_saac_case_activities sa on sa.id = a.external_id and a.external_table='us_saac_case_activities'
SET a.generated_uuid= sa.generated_uuid
where a.generated_uuid is null;

UPDATE us_courts_staging.activities a
    join us_courts.us_case_activities sa on sa.id = a.external_id and a.external_table='us_saac_case_activities'
SET a.generated_uuid= sa.generated_uuid
where a.generated_uuid is null;



