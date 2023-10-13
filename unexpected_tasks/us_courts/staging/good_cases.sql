use us_courts_staging;
select cas.court_id, count(*) from us_courts_staging.activities act
                                       join us_courts_staging.cases cas on cas.raw_id=act.case_id
                                       join cases_judges cj on act.id = cj.case_id
                                       join judges j on cj.judge_id = j.id
where act.pdf!=''
limit 10



use us_courts;

SELECT uci.case_id, uci.case_name,uci.case_filed_date,uci.status_as_of_date, uci.case_type,uci.judge_name,r.lawyer_name, r.gdrive_headshot_url, Concat('https://court-cases-activities.s3.amazonaws.com/',pdf.file)
from us_case_info uci
    join us_courts.us_case_activities_pdf pdf on pdf.case_id=uci.case_id
    join us_judges uj on uci.judge_name = uj.judge_name
    join us_judges_clean ujc on uj.id = ujc.judge_id
    join us_judges_mbo ujm on ujc.judge_id_mbo = ujm.id

    join us_case_party p on p.court_id = uci.court_id and p.case_id = uci.case_id and uci.deleted = 0
    join us_case_party_lawyers_cleaned c on p.id = c.raw_id and p.deleted = 0
    join us_case_party_lawyers_unique l on c.lawyer_id = l.id and not_a_lawyer = 0
    join us_case_laywers_mbo r on r.similar_to = l.similar_to and r.law_school is not null and r.law_school != ''

where ujc.judge_id_mbo is not null
  and uci.case_type rlike '^civil *$' and uci.court_id>2
limit 500


SELECT * from us_courts_staging.cases
    WHERE raw_id in ('A18A1161','A16A1865','A17I0249','A17I0249','A17A1717','A17A1979','A18A0379', 'A19A0378', 'A18A1964', 'A18A0652')


use us_courts_staging

SELECT * FROM cases_judges where case_id in (4890,5868,6019,7330,7343,7396,8117,8411,10160,2141276,2142255,2142406,2143724,2143737,2143790,2144511,2144805,2146554)
SELECT * FROM cases_lawyers where case_id in (4890,5868,6019,7330,7343,7396,8117,8411,10160,2141276,2142255,2142406,2143724,2143737,2143790,2144511,2144805,2146554)

use us_courts;

INSERT IGNORE INTO us_courts_staging.lawyers (external_id,full_name, first_name, middle_name, last_name, bio, picture, lawyer_limpar_uuid, created_by)

SELECT r.id,r.lawyer_name, r.lawyer_first_name, r.lawyer_middle_name, r.lawyer_last_name, r.bio_text, r.gdrive_headshot_url, r.law_limpar_ID, 'Maxim G'  from us_courts.us_case_party p
                  join us_case_party_lawyers_cleaned c on p.id = c.raw_id and p.deleted = 0
                  join us_case_party_lawyers_unique l on c.lawyer_id = l.id and not_a_lawyer = 0
                  join us_case_laywers_mbo r on r.similar_to = l.similar_to and r.law_school is not null and r.law_school != ''
where p.case_id in ('A18A1161','A16A1865','A17I0249','A17I0249','A17A1717','A17A1979','A18A0379', 'A19A0378', 'A18A1964', 'A18A0652')
and r.deleted=0


SELECT p.case_id,cs.id, lw.id lw_id, r.lawyer_name, r.lawyer_first_name, r.lawyer_middle_name, r.lawyer_last_name, r.bio_text, r.gdrive_headshot_url, r.law_limpar_ID, 'Maxim G'  from us_courts.us_case_party p
                                                                                                                                                                  join us_case_party_lawyers_cleaned c on p.id = c.raw_id and p.deleted = 0
                                                                                                                                                                  join us_case_party_lawyers_unique l on c.lawyer_id = l.id and not_a_lawyer = 0
                                                                                                                                                                  join us_case_laywers_mbo r on r.similar_to = l.similar_to and r.law_school is not null and r.law_school != ''
join us_courts_staging.cases cs on p.case_id=cs.raw_id
join us_courts_staging.lawyers lw on lw.full_name = p.party_name
where p.case_id in ('A18A1161','A16A1865','A17I0249','A17I0249','A17A1717','A17A1979','A18A0379', 'A19A0378', 'A18A1964', 'A18A0652')
  and r.deleted=0

