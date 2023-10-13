/* cases w/o judge name */

select ci.court_id, ct.court_name, count(*) count from us_case_info ci
    join us_courts_table ct on ct.court_id = ci.court_id where ci.judge_name is null or ci.judge_name = '' group by court_id

/* cases with judge and w/o judge bio */

SELECT court_id, count(*) from us_case_info where judge_name in (
    SELECT uj.judge_name
    from us_judges_clean ujc
             join us_judges uj on uj.id=ujc.judge_id
             join us_courts_table courts on courts.court_id = ujc.court_id
    where ujc.judge_id_mbo is null)
group by court_id

/* total judges*/

SELECT court_id, count(*) from us_judges_clean where judge_id_mbo is not null group by court_id;

/* total judges with bio */
SELECT court_id, count(*) from us_federal_judges_mbo_edition where court_id is not null group by court_id



/* list case_id with counts of judges with bio */
select uci.court_id, uci.case_id, jj.count_judges from us_case_info uci
    join (select uj.judge_name, count(*) count_judges from us_judges_clean ujc
        join us_judges uj on uj.id = ujc.judge_id where ujc.judge_id_mbo is not null group by ujc.judge_id) jj
            on uci.judge_name = jj.judge_name
where uci.deleted=0 group by uci.case_id order by jj.count_judges desc

/* list case_id with counts of parties with bio */
SELECT case_id, count(*) from us_case_party where party_name in (SELECT lawyer_name from rylan_lawyers) and deleted = 0 group by case_id


/* Connect count judges and parties  */

select uci.court_id, uci.case_id, jj.count_judges, law.count_lawyers from us_case_info uci
    join (select uj.judge_name, count(*) count_judges from us_judges_clean ujc
        join us_judges uj on uj.id = ujc.judge_id where ujc.judge_id_mbo is not null group by ujc.judge_id) jj
                                                                on uci.judge_name = jj.judge_name
    join (SELECT case_id, count(*) count_lawyers from us_case_party where court_id=1 and party_name in (SELECT lawyer_name from rylan_lawyers) and deleted = 0 group by case_id) law
                on uci.case_id = law.case_id
where court_id=1 and uci.deleted=0 group by uci.case_id order by jj.count_judges desc


SELECT ucp.case_id, count(*), jjj.jj.count_judges  from us_case_party ucp where court_id=1 and party_name in (SELECT lawyer_name from rylan_lawyers) and deleted = 0 group by case_id
join (select uci.court_id, uci.case_id, jj.count_judges from us_case_info uci
    join (select uj.judge_name, count(*) count_judges from us_judges_clean ujc
        join us_judges uj on uj.id = ujc.judge_id where ujc.judge_id_mbo is not null group by ujc.judge_id) jj
            on uci.judge_name = jj.judge_name
where uci.deleted=0 group by uci.case_id order by jj.count_judges desc) jjj on jjj.uci.case_id = ucp.case_id