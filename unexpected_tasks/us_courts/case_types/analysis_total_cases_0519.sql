select court.court_id, court.court_name, count(*) from us_courts.us_case_info info
                                                           join us_courts.us_courts_table court on court.court_id =info.court_id
where case_type rlike '^civil *$'
group by court_id


SELECT court_id, count(*)  from
(SELECT info.court_id, count(*) from us_courts.us_case_info info
join us_courts.us_case_report_aws_text text on info.case_id = text.case_id and text.court_id=info.court_id
where text.id in (SELECT DISTINCT report_text_id from litigation_case_type__IRL_keyword_to_text)
and info.case_type rlike '^civil *$'
group by text.case_id) aa
group by aa.court_id



SELECT aa.court_id, count(*) from
    (SELECT text.court_id from us_courts.us_case_report_aws_text text
join us_courts.us_case_info info on text.case_id=info.case_id and text.court_id=info.court_id
where text.id in (SELECT DISTINCT report_text_id from litigation_case_type__IRL_keyword_to_text)
  and info.case_type rlike '^civil *$'
group by text.case_id) aa
group by aa.court_id



select count(*) from
(SELECT info.case_id, text.case_id, text.id from us_courts.us_case_info info
                                        join us_courts.us_case_report_aws_text text on info.case_id = text.case_id
order by text.id) f


select f.court_id,count(*) from
(SELECT text.court_id, text.case_id from litigation_case_type__IRL_keyword_to_text keyword
join us_courts.us_case_report_aws_text text on text.id = keyword.report_text_id
group by text.case_id, text.court_id) f
join us_courts.us_case_info info on info.case_id = f.case_id and info.court_id = f.court_id
where info.case_type is null
group by f.court_id


select court_id, count(*) from us_courts.us_case_info
where case_type is null
group by court_id



CREATE TABLE us_courts_analysis.us_case_dismiss_temp
(SELECT act.court_id, ct.court_name, act.activity_decs, act.activity_type, act.case_id, info.case_name, Concat('https://court-cases-activities.s3.amazonaws.com/',pdf.file) pdf_link
FROM us_courts.us_case_activities_pdf pdf
    join us_courts.us_case_activities act on act.id=pdf.activity_id
    join us_courts.us_courts_table ct on ct.court_id=act.court_id
    join us_courts.us_case_info info on info.case_id=pdf.case_id
WHERE act.activity_decs rlike 'dismiss')



SELECT t.*
FROM us_courts_analysis.us_case_dismiss_temp2 as t,
     (SELECT ROUND((SELECT MAX(id) FROM us_courts_analysis.us_case_dismiss_temp2) * RAND()) AS rnd
      FROM us_courts_analysis.us_case_dismiss_temp2 LIMIT 6000) AS tmp
WHERE t.id IN (rnd)



SELECT t.*
FROM us_courts_analysis.litigation_case_type__matching_keyword as t,
     (SELECT ROUND((SELECT MAX(id) FROM us_courts_analysis.litigation_case_type__matching_keyword) * RAND()) AS rnd
      FROM us_courts_analysis.litigation_case_type__matching_keyword LIMIT 10000) AS tmp
WHERE t.id IN (rnd)


SELECT aa.court_id, count(*) from
    (SELECT text.court_id from us_courts.us_case_report_aws_text text
                                   join us_courts.us_case_info info on text.case_id=info.case_id and text.court_id=info.court_id
     where text.id in (SELECT DISTINCT report_text_id from litigation_case_type__IRL_keyword_to_text)
       and info.case_type rlike '^civil *$'
     group by text.case_id) aa
group by aa.court_id




SELECT pdf.court_id, c.court_name, pdf.case_id, info.case_name, info.case_type, Concat('https://court-cases-activities.s3.amazonaws.com/',pdf.file) pdf_link FROM us_courts.us_case_activities_pdf pdf
join us_case_info info on info.case_id = pdf.case_id and info.court_id = pdf.court_id
    join us_courts_table c on c.court_id = info.court_id
WHERE info.case_type rlike '^criminal *$' and info.deleted=0

