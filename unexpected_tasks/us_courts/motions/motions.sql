SELECT * FROM us_courts.us_case_activities act
                  join us_courts.us_case_relations_activity_pdf ucpoa on act.md5_hash = ucpoa.case_activities_md5
                  join us_courts.us_case_pdfs_on_aws u on ucpoa.case_pdf_on_aws_md5 = u.md5_hash
                  join us_courts_analysis.us_case_report_text rp on rp.pdf_on_aws_id = u.id
where act.activity_decs ='motion to dismiss' and rp.text_pdf like '%denied%';

SELECT court_id, case_id, aws_link FROM us_courts_analysis.us_case_report_text
where text_pdf like'%motion to dismiss%' and text_pdf like '%accepted%';


SELECT
    court_id, case_id, aws_link
FROM
    (
        SELECT
            rt.court_id, rt.case_id, rt.aws_link,
            @rn := IF(@prev = rt.court_id, @rn + 1, 1) AS rn,
            @prev := rt.court_id
        from us_courts_analysis.us_case_report_text rt
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where rt.text_pdf like'%motion to dismiss%' and rt.text_pdf like '%denied%'
        ORDER BY rt.court_id
    ) AS T1
WHERE rn <= 5;


SELECT
    court_id, case_id, aws_link
FROM
    (
        SELECT
            rt.court_id, rt.case_id, rt.aws_link,
            @rn := IF(@prev = rt.court_id, @rn + 1, 1) AS rn,
            @prev := rt.court_id
        from us_courts_analysis.us_case_report_text rt
                 JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        where rt.text_pdf like'%motion to dismiss%' and rt.text_pdf like '%accepted%'
        ORDER BY rt.court_id
    ) AS T1
WHERE rn <= 5;


