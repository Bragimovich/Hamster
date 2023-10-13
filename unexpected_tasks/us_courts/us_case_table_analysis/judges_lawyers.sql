use us_courts;

SELECT case_id, party_name from us_case_party ucp
                                              join us_case_laywers_mbo uclm on ucp.party_name = uclm.lawyer_name
where uclm.deleted=0 and court_id=17 and case_id in
(SELECT case_id from us_case_info where judge_name in (
    SELECT uj.judge_name
    from us_judges_clean ujc
             join us_judges uj on uj.id=ujc.judge_id
             join us_courts_table courts on courts.court_id = ujc.court_id
    where ujc.judge_id_mbo is not null) and court_id=17
group by case_id);



SELECT case_id, party_name, court_id from us_case_party ucp
                                              join us_case_laywers_mbo uclm on ucp.party_name = uclm.lawyer_name
where uclm.deleted=0 and court_id=1;


SELECT count(*) as c from us_case_info where judge_name in (
    SELECT uj.judge_name
    from us_judges_clean ujc
             join us_judges uj on uj.id=ujc.judge_id
             join us_courts_table courts on courts.court_id = ujc.court_id
    where ujc.judge_id_mbo is not null)
                                         and court_id=1
                                         and case_id in (SELECT case_id from us_case_party ucp
                                                                                 join us_case_laywers_mbo uclm on ucp.party_name = uclm.lawyer_name
                                                         where uclm.deleted=0 and court_id=1);



SELECT count(*) from us_case_info uci
    join us_judges uj on uj.judge_name = uci.judge_name
    join us_judges_clean ujc on uj.id = ujc.judge_id
    join us_judges_mbo ujm on ujc.judge_id_mbo = ujm.id
    where uci.court_id=1 and law_school_limpar_id is not null



SELECT * from us_case_party ucp
                  join us_case_laywers_mbo uclm on ucp.party_name = uclm.lawyer_name
                    join us_judges_mbo ujm on ujm.law_school_limpar_id = uclm.law_firm_limpar_id
where uclm.deleted=0 and ucp.court_id=17 and law_firm_limpar_id!='';

(SELECT law_school_limpar_id FROM us_judges_mbo)




