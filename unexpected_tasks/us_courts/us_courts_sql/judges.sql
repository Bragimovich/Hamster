use us_courts;

SELECT ujc.court_id, ujc.judge_id, ujc.judge_id_mbo, ujc.judge_name_clean, uj.judge_name, courts.court_name,
       j_mbo.court_state, j_mbo.court_type_A, j_mbo.court_type_B, j_mbo.judge_first_name, j_mbo.judge_middle_name, j_mbo.judge_last_name, j_mbo.judge_suffix,
       j_mbo.court_position, j_mbo.first_year_on_court, j_mbo.facebook_page, j_mbo.twitter, j_mbo.instagram, j_mbo.linked_in,
       j_mbo.university1, j_mbo.u1_limpar_id, j_mbo.u1_pipeline_id, j_mbo.u1_start_year, j_mbo.u1_end_year,
       j_mbo.university2, j_mbo.u2_limpar_id, j_mbo.u2_pipeline_id, j_mbo.u2_start_year, j_mbo.u2_end_year,
       j_mbo.law_school, j_mbo.law_school_limpar_id, j_mbo.law_school_pipeline_id, j_mbo.law_start_year, j_mbo.law_end_year,
       j_mbo.area_of_specialization, j_mbo.official_page_with_persons_bio, j_mbo.bio_copied_from_official_website, j_mbo.previous_law_firms, j_mbo.birthdate, j_mbo.birth_year, j_mbo.sex,
       j_mbo.childhood_town, j_mbo.professional_affiliation, j_mbo.political_affiliation, j_mbo.link_to_google_drive_headshot_picture, j_mbo.source_link
from us_judges_clean ujc
         join us_judges_mbo j_mbo on ujc.judge_id_mbo = j_mbo.id
         join us_judges uj on uj.id=ujc.judge_id
         join us_courts_table courts on courts.court_id = ujc.court_id



SELECT ujc.court_id, ujc.judge_id, ujc.judge_id_mbo, ujc.judge_name_clean, uj.judge_name, courts.court_name, courts.court_state, courts.court_type, courts.court_sub_type
from us_judges_clean ujc
         join us_judges uj on uj.id=ujc.judge_id
         join us_courts_table courts on courts.court_id = ujc.court_id
where ujc.judge_id_mbo is null


SELECT uj.judge_name
from us_judges_clean ujc
         join us_judges uj on uj.id=ujc.judge_id
         join us_courts_table courts on courts.court_id = ujc.court_id
where ujc.judge_id_mbo is not null
group by court_id


# count judges
SELECT court_id, count(*) from us_case_info WHERE judge_name in (
    SELECT uj.judge_name
    from us_judges uj
             join us_courts_table courts on courts.court_id = uj.court_id
)
group by court_id;


SELECT court_id, count(*) from us_judges_clean where judge_id_mbo is not null group by court_id;
SELECT court_id, count(*) from us_federal_judges_mbo_edition where court_id is not null group by court_id;



# cases w/o judge name
select ci.court_id, ct.court_name, count(*) count from us_case_info ci
    join us_courts_table ct on ct.court_id = ci.court_id where ci.judge_name is null or ci.judge_name = '' group by court_id

# cases with judge and w/o judge bio
SELECT court_id, count(*) from us_case_info where judge_name in (
    SELECT uj.judge_name
    from us_judges_clean ujc
             join us_judges uj on uj.id=ujc.judge_id
             join us_courts_table courts on courts.court_id = ujc.court_id
    where ujc.judge_id_mbo is null)
group by court_id

# total judges
SELECT court_id, count(*) from us_judges_clean where judge_id_mbo is not null group by court_id;
# total judges with bio
SELECT court_id, count(*) from us_judges_mbo where court_id is not null group by court_id


use us_courts
SELECT info.case_id,info.case_name, info.judge_name, mbo.judge_last_name from us_case_info info
    join us_judges uj on uj.judge_name = info.judge_name
    join us_judges_clean ujc on ujc.judge_id = uj.id
    join us_judges_mbo mbo on mbo.id = ujc.judge_id_mbo
where info.court_id = 1



# analysis matching in new tables


SELECT uci.court_id, count(*) old_analysis, new.ccc new_table from us_courts.us_case_info uci
            join (SELECT c.external_id court_id, count(*) ccc from us_courts_staging.cases
                join us_courts_staging.courts c on c.id = cases.court_id
            where cases.id not in (select case_id from us_courts_staging.cases_judges)
            group by  c.external_id) new on new.court_id=uci.court_id

where deleted=0 and judge_name in (
    SELECT uj.judge_name
    from us_courts.us_judges_clean ujc
             join us_courts.us_judges uj on uj.id=ujc.judge_id
             join us_courts.us_courts_table courts on courts.court_id = ujc.court_id
    where ujc.judge_id_mbo is null)

group by court_id


