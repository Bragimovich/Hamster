SELECT p.id, l.id, l.last_name, l.first_name, mbo.lawyer_name
FROM us_courts.us_case_laywers_mbo mbo
    join us_courts.us_case_party p on p.party_name = mbo.lawyer_name
    join us_courts_staging.lawyers l on l.last_name = SUBSTRING_INDEX(mbo.lawyer_name,' ', -1)
                    and l.first_name = SUBSTRING_INDEX(mbo.lawyer_name,' ', 1)

where p.court_id>1000;



INSERT IGNORE INTO us_courts_staging.cases_lawyers (case_id, lawyer_id, lawyer_type, created_by)
SELECT c.id, l.id, p.party_type, 'Maxim G.'
FROM us_courts.us_case_party p
         join us_courts_staging.lawyers l on l.last_name = SUBSTRING_INDEX(p.party_name,' ', -1)
                and l.first_name = SUBSTRING_INDEX(p.party_name,' ', 1)
        join us_courts_staging.cases c on c.raw_id = p.case_id
where p.court_id>1000;


SELECT p.id, mbo.id, p.party_name, mbo.lawyer_name
FROM us_courts.us_case_laywers_mbo mbo
         join us_courts.us_case_party p on p.party_name = mbo.lawyer_name



