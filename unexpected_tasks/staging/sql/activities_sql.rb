def raw_activities(limit, court, raw_court)
  <<~SQL
      SELECT act.id AS id, act.court_id AS raw_court_id, act.case_id AS raw_case_id,
            activity_date, activity_decs, activity_type,
            CONCAT('https://court-cases-activities.s3.amazonaws.com/',pdf.file) AS file, generated_uuid
      FROM us_case_activities AS act
        LEFT JOIN us_case_activities_pdf AS pdf
          ON pdf.activity_id = act.id
      WHERE act.id NOT IN (SELECT external_id
                          FROM us_courts_staging.activities
                          WHERE external_table = 'us_case_activities')
        AND TRIM(act.case_id) IN (SELECT raw_id
                                FROM us_courts_staging.cases
                                WHERE external_table = 'us_case_info'
                                  AND court_id = '#{court}')
        AND act.court_id = '#{raw_court}'
        AND !(activity_decs = ' ' AND pdf.file IS NULL)
        AND !(activity_decs = '\n' AND pdf.file IS NULL)
        AND !(activity_decs = 'Â ' AND pdf.file IS NULL)
        AND !(activity_decs IS NULL AND pdf.file IS NULL)
      LIMIT #{limit};
  SQL
end

def raw_activities_saac(limit, court, raw_court)
  <<~SQL
SELECT act.id AS id, act.court_id AS raw_court_id, act.case_id AS raw_case_id,
       activity_date, activity_desc, activity_type, pdf.aws_link AS file, generated_uuid
FROM us_saac_case_activities AS act
         LEFT JOIN us_saac_case_relations_activity_pdf AS rel
                   ON act.md5_hash = rel.case_activities_md5
         LEFT JOIN us_courts.us_saac_case_pdfs_on_aws AS pdf
                   ON pdf.md5_hash = rel.case_pdf_on_aws_md5
WHERE act.id NOT IN (SELECT external_id
                     FROM us_courts_staging.activities
                     WHERE external_table = 'us_saac_case_activities')
  AND TRIM(act.case_id) IN (SELECT raw_id
                            FROM us_courts_staging.cases
                            WHERE external_table = 'us_saac_case_info'
                              AND court_id = '#{court}')
  AND act.court_id = '#{raw_court}'
  AND !(activity_desc = ' ' AND pdf.aws_link IS NULL)
  AND !(activity_desc = '\n' AND pdf.aws_link IS NULL)
  AND !(activity_desc = 'Â ' AND pdf.aws_link IS NULL)
  AND !(activity_desc IS NULL AND pdf.aws_link IS NULL)
LIMIT #{limit};
  SQL
end

def courts(table)
  <<~SQL
    SELECT DISTINCT courts.external_id AS raw_court_id, courts.id AS court_id 
    FROM cases 
      JOIN courts 
        ON courts.id = cases.court_id 
    WHERE cases.external_table = "#{table}";
  SQL
end

def case_id(raw_case_id, court_id)
  <<~SQL
    SELECT id
    FROM cases
    WHERE raw_id = "#{raw_case_id}"
      AND court_id = "#{court_id}"
    LIMIT 1;
  SQL
end