SELECT
    court_id,
    case_id,
    data_source_url,
    rn

FROM
    (
        SELECT
            court_id,
            case_id,
            data_source_url,
            @rn := IF(@prev = court_id, @rn + 1, 1) AS rn,
            @prev := court_id
        FROM us_case_info
            JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where court_id is not null
        ORDER BY court_id
    ) AS T1
WHERE rn <= 5