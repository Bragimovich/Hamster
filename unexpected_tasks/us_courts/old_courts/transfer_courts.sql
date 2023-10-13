### Harris (court_id = 88)

# INFO TABLE
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_name, status_as_of_date, judge_name, created_by, data_source_url, md5_hash)
SELECT 88, case_number,file_date,type_desc,case_title,status,judge,created_by, data_source_url,
       md5(concat_ws('',88, case_number,file_date,type_desc,case_title,status,judge,created_by, data_source_url))
FROM usa_raw.new_harris_county_court_scrape;


#PARTY TABLE


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_type,party_name, party_address, party_city, party_state, party_zip, data_source_url, created_by, md5_hash)
SELECT 88, p_c.case_number, p_c.party_type, p_c.party_name, p_c.party_address, p_c.party_city, p_c.party_state, p_c.party_zip, p.data_source_url, p.created_by,
       md5(concat_ws('',88, p_c.case_number, p_c.party_type, p_c.party_name, p_c.party_address, p_c.party_city, p_c.party_state, p_c.party_zip,p.data_source_url, p.created_by))
FROM usa_raw.new_harris_county_court_case_parties_scrape_clear p_c
join usa_raw.new_harris_county_court_case_parties_scrape p on p.id = p_c.scrape_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type, party_name, party_address, party_city, party_state, party_zip, law_firm, data_source_url, created_by, md5_hash)
    SELECT 88,1, p_c.case_number, p_c.party_type, p_c.att_name, p_c.att_add, p_c.att_city, p_c.att_state, p_c.att_zip, p_c.att_org, p.data_source_url, p.created_by,
        md5(concat_ws('',88,1, p_c.case_number, p_c.party_type, p_c.att_name, p_c.att_add, p_c.att_city, p_c.att_state, p_c.att_zip, p_c.att_org, p.data_source_url, p.created_by))
FROM usa_raw.new_harris_county_court_case_parties_scrape_clear p_c
         join usa_raw.new_harris_county_court_case_parties_scrape p on p.id = p_c.scrape_id
where  p_c.att_name is not null;


#ACtivities table

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, data_source_url, created_by, md5_hash)
SELECT 88, case_number, case_activity, date, data_source_url, created_by,
       md5(concat_ws('',88, case_number, case_activity, date, data_source_url, created_by))
FROM usa_raw.new_harris_county_court_case_activity_scrape;



### U.S. District Court for the Southern District of Illinois (court_id=98)

# Info

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_description, judge_name, created_by, data_source_url, md5_hash)
SELECT 98, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main,
       md5(concat_ws('',98, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main))
FROM usa_raw.southern_il_court_case_activity_scrape;


#activities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_date, activity_decs,  activity_pdf, md5_hash)
SELECT 98, case_number, date_filed, docket_text, pdf_url,
       md5(concat_ws('',98, case_number, date_filed, docket_text, pdf_url))
    from (SELECT case_number, activity.date_filed, docket_text, pdf_url from usa_raw.southern_il_court_case_activity_scrape__pdf activity
        join usa_raw.southern_il_court_case_activity_scrape info on activity.case_id = info.id) t;

#party

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, is_lawyer, party_type, party_address, law_firm, md5_hash)
    SELECT 98, case_number, name, is_lawyer, type, address, firm_name,
           md5(concat_ws('',98, case_number, name, is_lawyer, type, address, firm_name))
from (SELECT info.case_number, lawyers.name, 1 as is_lawyer, CONCAT(parties.type, ' lawyer') type, lawyers.address, firm_name
    from usa_raw.southern_il_court_case_activity_scrape__attorney lawyers
    join usa_raw.southern_il_court_case_activity_scrape__parties_attorney_ids relation
        on lawyers.id = relation.attorney_id
    join usa_raw.southern_il_court_case_activity_scrape__parties parties
        on parties.id = relation.party_id
    join usa_raw.southern_il_court_case_activity_scrape__parties_clear clear
        on clear.name = parties.name
    join usa_raw.southern_il_court_case_activity_scrape info
        on clear.scrape_id = info.id) t;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, md5_hash)
    SELECT 98, case_number, name, type,
           md5(concat_ws('',98, case_number, name, type))
        from (SELECT case_number, clear.name, clear.type from usa_raw.southern_il_court_case_activity_scrape__parties_clear clear join usa_raw.southern_il_court_case_activity_scrape info on clear.scrape_id = info.id) t;


# DELAWARE (court_ID=87)

#INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_name, created_by, data_source_url, md5_hash)
    SELECT 87, case_number,filed_date,case_type,case_title,created_by, data_source_url,
           md5(concat_ws('',87, case_number,filed_date,case_type,case_title,created_by, data_source_url))
    FROM usa_raw.delaware_county_court_case_scrape;


# PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, party_address, party_city,party_state, party_zip, law_firm,created_by, data_source_url, md5_hash)
    SELECT 87, pc.case_number, pc.party_name, pc.party_type, pc.party_address, pc.party_city, pc.party_state, pc.party_zip, pc.party_name, s.created_by, s.data_source_url,
           md5(concat_ws('',87, pc.case_number, pc.party_name, pc.party_type, pc.party_address, pc.party_city, pc.party_state, pc.party_zip, s.created_by, s.data_source_url))
    from usa_raw.delaware_county_court_parties_clear pc
join usa_raw.delaware_county_court_case_scrape s on pc.case_number = s.case_number
where party_class='Organization';

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, party_address, party_city,party_state, party_zip,created_by, data_source_url, md5_hash)
SELECT 87, pc.case_number, pc.party_name, pc.party_type, pc.party_address, pc.party_city, pc.party_state, pc.party_zip, s.created_by, s.data_source_url,
       md5(concat_ws('',87, pc.case_number, pc.party_name, pc.party_type, pc.party_address, pc.party_city, pc.party_state, pc.party_zip, s.created_by, s.data_source_url))
from usa_raw.delaware_county_court_parties_clear pc
         join usa_raw.delaware_county_court_case_scrape s on pc.case_number = s.case_number
where party_class!='Organization';


# Activities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id,activity_type, activity_date, activity_decs,  activity_pdf,created_by,data_source_url, md5_hash)
SELECT 87, a.case_number, a.case_activity_type, a.date, a.case_activity, a.pdf_path, s.created_by, s.data_source_url,
       md5(concat_ws('', 87, a.case_number, a.case_activity_type, a.date, a.case_activity, a.pdf_path, s.created_by, s.data_source_url))
from usa_raw.delaware_county_court_case_activity_scrape a
         join usa_raw.delaware_county_court_case_scrape s on a.case_number = s.case_number;

# UPDATE us_courts.us_case_activities a
#     join usa_raw.delaware_county_court_case_activity_scrape s on s.case_activity = a.activity_decs and s.case_number = a.case_id
# SET a.activity_pdf = s.pdf_path
# WHERE a.court_id=87 AND a.activity_pdf like 'https://delcopublicaccess.co.delaware.pa.us%';


# U.S. District Court for the Western District of Pennsylvania (court_id = 94)

# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_description, judge_name, created_by, data_source_url, md5_hash)
    SELECT 94, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main,
           md5(concat_ws('',94, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main))
    FROM usa_raw.pennsylvania_western_d_scrape;

# Activities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_date, activity_decs,  activity_pdf, md5_hash)
SELECT 94, case_number, date_filed, docket_text, pdf_url,
       md5(concat_ws('',94, case_number, date_filed, docket_text, pdf_url))
    from (SELECT case_number, activity.date_filed, docket_text, pdf_url from usa_raw.pennsylvania_western_d_scrape__pdf activity
        join usa_raw.pennsylvania_western_d_scrape info on activity.case_id = info.id) t;


# PARTY

        # Attorney
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, md5_hash)
SELECT 94, case_number, name, type, md5(concat_ws('',94, case_number, name, type))
from (SELECT case_number, clear.name, clear.type from usa_raw.pennsylvania_western_d_scrape__parties_clear clear
join usa_raw.pennsylvania_western_d_scrape__parties parties
on clear.scrape_id = parties.id
join usa_raw.pennsylvania_western_d_scrape__parties_ids case_rel
on case_rel.party_id = parties.id
join usa_raw.pennsylvania_western_d_scrape info
on case_rel.case_id = info.id) t;

        # Party
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, is_lawyer, party_type, party_address, law_firm, md5_hash)
SELECT 94, case_number, name, is_lawyer, type, address, firm_name,
       md5(concat_ws('',94, case_number, name, is_lawyer, type, address, firm_name))
from (SELECT info.case_number, lawyers.name, 1 as is_lawyer, CONCAT(parties.type, ' lawyer') type, lawyers.address, firm_name
      from usa_raw.pennsylvania_western_d_scrape__attorney lawyers
               join usa_raw.pennsylvania_western_d_scrape__parties_ids relation
                    on lawyers.id = relation.party_id
               join usa_raw.pennsylvania_western_d_scrape__parties parties
                    on parties.id = relation.party_id
               join usa_raw.pennsylvania_western_d_scrape__parties_ids case_rel
                    on case_rel.party_id = parties.id
               join usa_raw.pennsylvania_western_d_scrape info
                    on case_rel.case_id = info.id) t;


# Contra Costa Superior Court (court_id =85)


# info

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_type, data_source_url, created_by, md5_hash)
SELECT 85, case_number, case_type, data_source_url, created_by,
       md5(concat_ws('',85, case_number, case_type, data_source_url, created_by))
FROM usa_raw.contra_costa_court_case_scrape_2;


        # activities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, data_source_url, created_by, md5_hash)
         SELECT 85, case_number, case_activity, date, data_source_url, created_by,
                md5(concat_ws('',85, case_number, case_activity, date, data_source_url, created_by))
         FROM usa_raw.contra_costa_court_case_activity_scrape_2;

        # activities-complaint
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_type, activity_decs, activity_date, data_source_url, created_by, md5_hash)
    SELECT 85, case_number, complaint_type, complaint_status, filing_date, data_source_url, created_by,
           md5(concat_ws('',85, case_number, complaint_type, complaint_status, filing_date, data_source_url, created_by))
    FROM usa_raw.contra_costa_court_complaints_2;


        # Party

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_type, party_name,law_firm, party_description, data_source_url, created_by, md5_hash)
     SELECT 85, pc.case_number, 0, pc.type, pc.name,pc.name, p2.party_status, p2.data_source_url, p2.created_by,
            md5(concat_ws('',85, pc.case_number, 0, pc.type, pc.name,pc.name, p2.party_status, p2.data_source_url, p2.created_by))
     FROM usa_raw.contra_costa_court_parties_clear pc
    join usa_raw.contra_costa_court_parties_2 p2 on pc.scrape_id = p2.id
    where pc.class = 'Organization';

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_type, party_name, party_description, data_source_url, created_by, md5_hash)
SELECT 85, pc.case_number, 0, pc.type, pc.name,p2.party_status, p2.data_source_url, p2.created_by,
       md5(concat_ws('',85, pc.case_number, 0, pc.type, pc.name, p2.party_status, p2.data_source_url, p2.created_by))
FROM usa_raw.contra_costa_court_parties_clear pc
         join usa_raw.contra_costa_court_parties_2 p2 on pc.scrape_id = p2.id
    where pc.class != 'Organization';


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_address, party_type, party_description, data_source_url, created_by, md5_hash)
    SELECT 85, p.case_number, 1, a.attorney_full_name, CONCAT_WS(', ', a.attorney_address, a.city_state_zip), a.representation, a.phone, a.data_source_url, a.created_by,
           md5(concat_ws('',85, p.case_number, 1, a.attorney_full_name, CONCAT_WS(', ', a.attorney_address, a.city_state_zip), a.representation, a.phone, a.data_source_url, a.created_by))
FROM usa_raw.contra_costa_court_attorneys_2 a
JOIN usa_raw.contra_costa_court_attorneys_relation_2 r ON a.id = r.attorney_id
JOIN usa_raw.contra_costa_court_parties_2 p ON p.id = r.party_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_type, party_name, party_description, data_source_url, created_by, md5_hash)
SELECT 85, p2.case_number, 0, p2.party_type, p2.party_name, p2.party_status, p2.data_source_url, p2.created_by,
       md5(concat_ws('',85, p2.case_number, 0, p2.party_type, p2.party_name, p2.party_status, p2.data_source_url, p2.created_by))
    FROM usa_raw.contra_costa_court_parties_2 p2
WHERE p2.id not in (SELECT scrape_id from usa_raw.contra_costa_court_parties_clear);



# Superior Court of California for San Francisco County (Court_id=97)

         # INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_description, created_by, data_source_url, md5_hash)
SELECT 97, case_number, case_date, case_type, case_category, created_by, data_source_url,
    md5(concat_ws('',97, case_number, case_date, case_type, case_category, created_by, data_source_url))
FROM usa_raw.san_francisco_county_court_scrape;


        # ACTIVITIES

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date,  activity_pdf, created_by, data_source_url, md5_hash)
 SELECT 97, case_number, case_activity, date, pdf_url, created_by, data_source_url,
        md5(concat_ws('',97, case_number, case_activity, date, pdf_url, created_by, data_source_url))
FROM usa_raw.san_francisco_court_case_activity_scrape;


# UPDATE us_courts.us_case_activities a
#     join usa_raw.san_francisco_court_case_activity_scrape s on s.case_activity = a.activity_decs and s.case_number = a.case_id
# SET a.activity_pdf = s.pdf_url
# WHERE a.court_id=97 AND a.activity_pdf is null and s.pdf_url is not null;


        # PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT 97, case_number, party_name, party_type, created_by, data_source_url,
       md5(concat_ws('',97, case_number, party_name, party_type, created_by, data_source_url))
FROM
    (SELECT clear.case_number, clear.party_name, clear.party_type, created_by, data_source_url from usa_raw.san_francisco_court_parties_scrape_clear clear
        join usa_raw.san_francisco_court_parties_scrape party on party.id = clear.scrape_id
        where clear.party_class != 'John Doe') t;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, is_lawyer, law_firm, party_address, party_city, party_state, party_zip, created_by, data_source_url, md5_hash)
SELECT 97, case_number, attorney_name, party_type, is_lawyer, attorney_org, attorney_address, attorney_city, attorney_state, attorney_zip, created_by, data_source_url,
       md5(concat_ws('',97, case_number, attorney_name, party_type, is_lawyer, attorney_org, attorney_address, attorney_city, attorney_state, attorney_zip, created_by, data_source_url))
    FROM (SELECT clear.case_number, clear.attorney_name, CONCAT(clear.party_type, ' Lawyer') party_type, 1 as is_lawyer,  clear.attorney_org, clear.attorney_address, clear.attorney_city, clear.attorney_state, clear.attorney_zip,party.created_by, party.data_source_url
        from usa_raw.san_francisco_court_parties_scrape_clear clear
            join usa_raw.san_francisco_court_parties_scrape party on party.id = clear.scrape_id
        where clear.attorney_name is not null or clear.attorney_name != '') t;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, created_by, data_source_url,md5_hash)
SELECT  97, case_number, party_name, party_type, created_by, data_source_url,
    md5(concat_ws('',97, case_number, party_name, party_type, created_by, data_source_url))
FROM usa_raw.san_francisco_court_parties_scrape
    where id in (SELECT scrape_id from usa_raw.san_francisco_court_parties_scrape_clear where party_class = 'John Doe');


# San Bernardino County Superior Court (court_id = 96)

        # INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_description, created_by, data_source_url, md5_hash)
SELECT 96, case_number, date_filed, division, case_type, created_by, data_source_url,
       md5(concat_ws('',96, case_number, date_filed, division, case_type, created_by, data_source_url))
FROM usa_raw.san_bernardino_county_court_case_scrape;



        # PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT 96, case_number, party_name, party_type, created_by, data_source_url,
       md5(concat_ws('',96, case_number, party_name, party_type, created_by, data_source_url))
FROM
(SELECT clear.case_number, clear.party_name, clear.party_type, created_by, data_source_url
 from usa_raw.san_bernardino_county_court_parties_clear clear
join usa_raw.san_bernardino_county_court_parties party
on party.id = clear.scrape_id group by case_number, party_name, party_type) t;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, is_lawyer, party_type, party_address, party_city, created_by, data_source_url, md5_hash)
SELECT 96, case_number, attorney_full_name, is_lawyer, type, attorney_address, city_state_zip, created_by, data_source_url,
       md5(concat_ws('',96, case_number, attorney_full_name, is_lawyer, type, attorney_address, city_state_zip, created_by, data_source_url))
from (SELECT parties.case_number, lawyers.attorney_full_name, 1 as is_lawyer, CONCAT(parties.party_type, ' Lawyer') type, lawyers.attorney_address, city_state_zip,
lawyers.created_by, lawyers.data_source_url
from usa_raw.san_bernardino_county_court_attorneys lawyers
join usa_raw.san_bernardino_county_court_attorneys_relation relation
on lawyers.id = relation.attorney_id
join usa_raw.san_bernardino_county_court_parties parties
on parties.id = relation.party_id
where representation = 'Lawyer') t;


        # ACTIVITIES

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, created_by, data_source_url, md5_hash)
SELECT 96, case_number, case_activity, date, created_by, data_source_url,
       md5(concat_ws('',96, case_number, case_activity, date, created_by, data_source_url))
       FROM usa_raw.san_bernardino_county_court_activity_scrape;


INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_date, activity_type, activity_decs, created_by, data_source_url, md5_hash)
SELECT 96, case_number, filing_date, complaint_type, complaint_status, created_by, data_source_url,
       md5(concat_ws('',96, case_number, filing_date, complaint_type, complaint_status, created_by, data_source_url))
from usa_raw.san_bernardino_county_court_complaints;


# Pinellas Circuit Court (court_id = 95)

        # INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_name, case_filed_date, case_type,  case_description, judge_name, data_source_url, created_by, md5_hash)
SELECT 95, case_number, style_defendant_info, date_filed, case_category, case_type, judicial_officer, data_source_url, created_by,
       md5(concat_ws('',95, case_number, style_defendant_info, date_filed, case_category, case_type, judicial_officer, data_source_url, created_by))
    FROM (SELECT scrape.case_number, style_defendant_info, date_filed, case_category, case_type, judicial_officer, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url, created_by
            FROM usa_raw.pinellas_county_circuit_court_scrape scrape
                JOIN usa_raw.pinellas_county_circuit_court_list list on scrape.list_id = list.id) t;

        # ACTIVITIES

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_type, activity_decs, activity_date, activity_pdf, created_by, data_source_url, md5_hash)
SELECT 95, case_number, case_activity_type, case_activity_desc, date, s3_url, created_by, data_source_url,
       md5(concat_ws('',95, case_number, case_activity_type, case_activity_desc, date, s3_url, created_by, data_source_url))
FROM (SELECT activity.case_number, case_activity_type, case_activity_desc, date, s3_url, activity.created_by, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess/', image) as data_source_url
    from usa_raw.pinellas_county_circuit_court_case_activity_scrape activity
        join usa_raw.pinellas_county_circuit_court_list list on activity.list_id = list.id
        join usa_raw.pinellas_county_circuit_court_case_activity_image image on image.list_id = list.id) t;

# JUDGMENT

INSERT IGNORE INTO us_court_cases.old_court_case_judgment (court_id, case_id, party_name, activity_type, case_type, requested_amount,judgment_amount, judgment_date, created_by, data_source_url, md5_hash)
SELECT 95, i.case_number, i.financial_name, ev.event_title, list.type,  i.total_assessment, i.total_payments_credits, ev.event_date,  i.created_by, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', list.case_link),
       md5(concat_ws('',95, i.case_number, i.financial_name, i.total_assessment, i.total_payments_credits, ev.event_date,  i.created_by, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', list.case_link)))
       FROM usa_raw.pinellas_county_circuit_court_case_financial_info i
        join usa_raw.pinellas_county_circuit_court_case_financial_events ev on ev.list_id = i.list_id
        JOIN usa_raw.pinellas_county_circuit_court_list list on ev.list_id = list.id;


        # PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
   SELECT 95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url,
          md5(concat_ws('',95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url))
   FROM
   (SELECT clear.case_number, clear.defendant_name as party_name, 'Defendant' as party_type, clear.defendant_address as party_address,
   clear.defendant_city as party_city, clear.defendant_state as party_state, clear.defendant_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
   from usa_raw.pinellas_county_circuit_court_scrape_clear clear
   join usa_raw.pinellas_county_circuit_court_list list
   on list.id = clear.list_id where clear.defendant_name is not null and clear.defendant_name != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url,md5_hash)
SELECT 95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.plaintiff_name as party_name, 'Plaintiff' as party_type, clear.plaintiff_address as party_address,
clear.plaintiff_city as party_city, clear.plaintiff_state as party_state, clear.plaintiff_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.plaintiff_name is not null and clear.plaintiff_name != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
SELECT 95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.respondent_name as party_name, 'Respondent' as party_type, clear.respondent_address as party_address,
clear.respondent_city as party_city, clear.respondent_state as party_state, clear.respondent_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.respondent_name is not null and clear.respondent_name != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
SELECT 95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.petitioner_name as party_name, 'Petitioner' as party_type, clear.petitioner_address as party_address,
clear.petitioner_city as party_city, clear.petitioner_state as party_state, clear.petitioner_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.petitioner_name is not null and clear.petitioner_name != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, is_lawyer, law_firm, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
SELECT 95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.defendant_attorney as party_name, 'Defedant Lawyer' as party_type, 1 as is_lawyer, defendant_attorney_company as party_law_firm, clear.defendant_attorney_address as party_address,
clear.defendant_attorney_city as party_city, clear.defendant_attorney_state as party_state, clear.defendant_attorney_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.defendant_attorney is not null and clear.defendant_attorney != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, is_lawyer, law_firm, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
SELECT 95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.plaintiff_attorney as party_name, 'Plaintiff Lawyer' as party_type, 1 as is_lawyer, plaintiff_attorney_company as party_law_firm, clear.plaintiff_attorney_address as party_address,
clear.plaintiff_attorney_city as party_city, clear.plaintiff_attorney_state as party_state, clear.plaintiff_attorney_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.plaintiff_attorney is not null and clear.plaintiff_attorney != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, is_lawyer, law_firm, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
SELECT 95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.respondent_attorney as party_name, 'Respondent Lawyer' as party_type, 1 as is_lawyer, respondent_attorney_company as party_law_firm, clear.respondent_attorney_address as party_address,
clear.respondent_attorney_city as party_city, clear.respondent_attorney_state as party_state, clear.respondent_attorney_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.respondent_attorney is not null and clear.respondent_attorney != '') t;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, party_type, is_lawyer, law_firm, party_address, party_city, party_state, party_zip, data_source_url, md5_hash)
SELECT 95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url,
       md5(concat_ws('',95, case_number, party_name, party_type, is_lawyer, party_law_firm, party_address, party_city, party_state, party_zip, data_source_url))
FROM
(SELECT clear.case_number, clear.petitioner_attorney as party_name, 'Petitioner Lawyer' as party_type, 1 as is_lawyer, petitioner_attorney_company as party_law_firm, clear.petitioner_attorney_address as party_address,
clear.petitioner_attorney_city as party_city, clear.petitioner_attorney_state as party_state, clear.petitioner_attorney_zip as party_zip, CONCAT('https://ccmspa.pinellascounty.org/PublicAccess', case_link) as data_source_url
from usa_raw.pinellas_county_circuit_court_scrape_clear clear
join usa_raw.pinellas_county_circuit_court_list list
on list.id = clear.list_id where clear.petitioner_attorney is not null and clear.petitioner_attorney != '') t;


# U.S. District Court for the Eastern District of Pennsylvania (court_id=93)

        # INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_description, judge_name, created_by, data_source_url, md5_hash)
SELECT 93, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main,
       md5(concat_ws('',93, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main))
FROM usa_raw.pennsylvania_eastern_d_scrape;

        # Activities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_date, activity_decs,  activity_pdf, md5_hash)
SELECT 93, case_number, date_filed, docket_text, pdf_url,
       md5(concat_ws('',93, case_number, date_filed, docket_text, pdf_url))
    from (SELECT case_number, activity.date_filed, docket_text, pdf_url from usa_raw.pennsylvania_eastern_d_scrape__pdf activity
        join usa_raw.pennsylvania_eastern_d_scrape info on activity.case_id = info.id) t;



        # Party


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, is_lawyer, party_type, party_address, law_firm, md5_hash)
    SELECT 93, case_number, name, is_lawyer, type, address, firm_name,
           md5(concat_ws('',93, case_number, name, is_lawyer, type, address, firm_name))
from (SELECT info.case_number, lawyers.name, 1 as is_lawyer, CONCAT(parties.type, ' lawyer') type, lawyers.address, firm_name
    from usa_raw.pennsylvania_eastern_d_scrape__attorney lawyers
    join usa_raw.southern_il_court_case_activity_scrape__parties_attorney_ids relation
        on lawyers.id = relation.attorney_id
    join usa_raw.pennsylvania_eastern_d_scrape__parties parties
        on parties.id = relation.party_id
    join usa_raw.pennsylvania_eastern_d_scrape__parties_ids case_rel
        on case_rel.party_id = parties.id
    join usa_raw.pennsylvania_eastern_d_scrape info
        on case_rel.case_id = info.id) t;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, md5_hash)
SELECT 93, case_number, name, type, md5(concat_ws('',93, case_number, name, type))
    from (SELECT case_number, clear.name, clear.type from usa_raw.pennsylvania_eastern_d_scrape__parties_clear clear
    join usa_raw.pennsylvania_eastern_d_scrape__parties parties
    on clear.scrape_id = parties.id
    join usa_raw.pennsylvania_eastern_d_scrape__parties_ids case_rel
    on case_rel.party_id = parties.id
    join usa_raw.pennsylvania_eastern_d_scrape info
    on case_rel.case_id = info.id) t;



# U.S. District Court for the Eastern District of Louisiana (court_id =90)

        # INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,  case_description, judge_name, created_by, data_source_url, md5_hash)
SELECT 90, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main,
       md5(concat_ws('',90, case_number, date_filed, case_category, nature_of_suit, assigned_to, created_by, url_main))
FROM usa_raw.louisiana_court_case_scrape;


        # ACTIVITIES

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_date, activity_decs,  activity_pdf, md5_hash)
SELECT 90, case_number, date_filed, docket_text, pdf_url,
md5(concat_ws('',90, case_number, date_filed, docket_text, pdf_url))
from (SELECT case_number, activity.date_filed, docket_text, pdf_url from usa_raw.louisiana_court_case_scrape__pdf activity
join usa_raw.louisiana_court_case_scrape info on activity.case_id = info.id) t;


        # PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, is_lawyer, party_type, party_address, law_firm, md5_hash)
    SELECT 90, case_number, name, is_lawyer, type, address, firm_name,
           md5(concat_ws('',90, case_number, name, is_lawyer, type, address, firm_name))
from (SELECT info.case_number, lawyers.name, 1 as is_lawyer, CONCAT(parties.type, ' lawyer') type, lawyers.address, firm_name
    from usa_raw.louisiana_court_case_scrape__attorney lawyers
    join usa_raw.louisiana_court_case_scrape__parties_attorney_ids relation
        on lawyers.id = relation.attorney_id
    join usa_raw.louisiana_court_case_scrape__parties parties
        on parties.id = relation.party_id
    join usa_raw.louisiana_court_case_scrape__parties_ids case_rel
        on case_rel.party_id = parties.id
    join usa_raw.louisiana_court_case_scrape info
        on case_rel.case_id = info.id) t;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name, party_type, md5_hash)
SELECT 90, case_number, name, type, md5(concat_ws('',90, case_number, name, type))
    from (SELECT case_number, clear.name, clear.type from usa_raw.louisiana_court_case_scrape__parties_clear clear
    join usa_raw.louisiana_court_case_scrape__parties parties
    on clear.scrape_id = parties.id
    join usa_raw.louisiana_court_case_scrape__parties_ids case_rel
    on case_rel.party_id = parties.id
    join usa_raw.louisiana_court_case_scrape info
    on case_rel.case_id = info.id) t;


# Alameda County Superior Court		(court_id = 81)

        # INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_name, case_filed_date, case_type, judge_name, created_by, data_source_url, md5_hash)
SELECT
    81 AS court_id, s.case_number, d.case_title, s.filing_date, s.case_type, d.judge,  s.created_by, s.data_source_url,
    md5(concat_ws(81, s.case_number, d.case_title, s.filing_date, s.case_type, d.judge,  s.created_by, s.data_source_url)) AS md5_hash
FROM usa_raw.alameda_county_court_case_scrape s
         join usa_raw.alameda_court_docket_scrape d on d.case_number = s.case_number;


        # PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_type, party_name, created_by, data_source_url, md5_hash)
SELECT
    81 AS court_id, party_clear.case_number, party_clear.party_type, party_clear.party_name, party.created_by, s.data_source_url,
    md5(concat_ws(81, party_clear.case_number, party_clear.case_number, party_clear.party_type, party_clear.party_name, party.created_by)) AS md5_hash
FROM usa_raw.alameda_county_court_parties_scrape_clear AS party_clear
         JOIN usa_raw.alameda_county_court_parties_scrape party
              ON party_clear.scrape_id = party.id
        join usa_raw.alameda_county_court_case_scrape s on party.case_number = s.case_number
where party_clear.party_class!='Organization';


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_type, party_name,law_firm, created_by, data_source_url, md5_hash)
SELECT
    81 AS court_id, party_clear.case_number, party_clear.party_type, party_clear.party_name,party_clear.party_name, party.created_by, s.data_source_url,
    md5(concat_ws(81, party_clear.case_number, party_clear.case_number, party_clear.party_type, party_clear.party_name, party.created_by)) AS md5_hash
FROM usa_raw.alameda_county_court_parties_scrape_clear AS party_clear
         JOIN usa_raw.alameda_county_court_parties_scrape party
              ON party_clear.scrape_id = party.id
         join usa_raw.alameda_county_court_case_scrape s on party.case_number = s.case_number
where party_clear.party_class='Organization';

        # Activities


INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, created_by, md5_hash)
SELECT
    81 AS court_id, case_number, case_activity, date, created_by,
    md5(concat_ws(81, case_number, case_activity, date, created_by)) AS md5_hash
FROM usa_raw.alameda_county_court_case_activity_scrape;


# State of California Superior Court - Kern County (court_id = 83)

        # INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, created_by, data_source_url, md5_hash)
    SELECT 83, case_number,date_filed,case_type,created_by, data_source_url,
           md5(concat_ws('',83, case_number,date_filed,case_type,created_by, data_source_url))
FROM usa_raw.ca_kern_county_court_case_scrape;


        # Activties

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, data_source_url, created_by, md5_hash)
SELECT 83, case_number, case_activity_description, case_activity_date, data_source_url, created_by,
       md5(concat_ws('',83, case_number, case_activity_description, case_activity_date, data_source_url, created_by))
FROM usa_raw.ca_kern_court_case_activity_scrape;


        # PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type,party_name, data_source_url, created_by, md5_hash)
SELECT 83, 0, p_c.case_number, p_c.party_type, p_c.party_name, p.data_source_url, p.created_by,
       md5(concat_ws('',83,0, p_c.case_number, p_c.party_type, p_c.party_name,p.data_source_url, p.created_by))
FROM usa_raw.ca_kern_county_court_parties_clear p_c
    join usa_raw.ca_kern_county_court_case_parties_scrape p on p.id = p_c.scrape_id;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type,party_name, data_source_url, created_by, md5_hash)
SELECT 83, 0, p_c.case_number, p_c.party_type, p_c.party_name, p_c.data_source_url, p_c.created_by,
       md5(concat_ws('',83,0, p_c.case_number, p_c.party_type, p_c.party_name,p_c.data_source_url, p_c.created_by))
FROM usa_raw.ca_kern_county_court_case_parties_scrape p_c
    where p_c.case_number not in (SELECT case_number from usa_raw.ca_kern_county_court_parties_clear);


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type,party_name, data_source_url, created_by, md5_hash)
SELECT 83, 1, p.case_number, 'Attorney', a.attorney_name_clear, p.data_source_url, p.created_by,
           md5(concat_ws('',83, 1, p.case_number, 'Attorney', a.attorney_name_clear, p.created_by, p.data_source_url))
               FROM usa_raw.ca_kern_county_court_case_attorneys_scrape a
join usa_raw.ca_kern_county_court_case_attorneys_relation a_r on a_r.attorney_id = a.id
join usa_raw.ca_kern_county_court_case_parties_scrape p on a_r.party_id = p.id;

## Orange County Superior Court (84) (CHECK IT)

# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, case_name, created_by, data_source_url, md5_hash)
SELECT 84, ds.case_id, s.date_filed, ds.case_type, ds.case_title, s.created_by, s.data_source_url,
       md5(concat_ws('',84, ds.case_id, s.date_filed, ds.case_type,ds.case_title, s.data_source_url, s.created_by))
FROM usa_raw.ca_orange_county_court_case_docket_scrape AS ds
    JOIN usa_raw.ca_orange_county_court_case_scrape AS s ON s.case_number = ds.case_id;

# party

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type,party_name, data_source_url, created_by, md5_hash)
SELECT 84, 0, pc.case_number, pc.party_type, pc.party_name, ps.data_source_url, ps.created_by,
       md5(concat_ws('',84,0, pc.case_number, pc.party_type, pc.party_name, ps.data_source_url, ps.created_by)) from usa_raw.ca_orange_county_court_parties_clear AS pc
    join usa_raw.ca_orange_county_court_case_parties_scrape AS ps on ps.id = pc.scrape_id;


# activities
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, data_source_url, created_by, md5_hash)
SELECT 84, appeal_case_number, case_activity_description, case_activity_date, data_source_url, created_by,
       md5(concat_ws('',84, appeal_case_number, case_activity_description, case_activity_date, data_source_url, created_by))
FROM usa_raw.ca_orange_county_court_case_activity_scrape;


# California 4th District Court of Appeal (cout =82) (Check it)

        # INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, created_by, data_source_url, md5_hash)
SELECT
    82 AS court_id, appeal_case_number, date_filed, case_type, created_by, data_source_url,
    md5(concat_ws(82, appeal_case_number, date_filed, case_type, created_by, data_source_url)) AS md5_hash
FROM usa_raw.ca_4th_appellate_court_case_scrape;

        # party

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_type, party_name, party_address, created_by, data_source_url, md5_hash)
SELECT
    82, case_number, type, name, address, created_by, data_source_url,
    md5(concat_ws(82, case_number, type, name, address, created_by, data_source_url))
FROM usa_raw.ca_4th_appellate_court_case_parties_scrape;


# act

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, created_by, data_source_url, md5_hash)
SELECT
    82 AS court_id, case_number, case_activity_date, case_activity_date, created_by, data_source_url,
    md5(concat_ws(82, case_number, case_activity_date, case_activity_date, created_by, data_source_url)) AS md5_hash
FROM usa_raw.ca_4th_appellate_court_case_activity_scrape;



# St. Louis 22nd Judicial Circuit Court (91) (CHECK IT)

# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info
(court_id, case_id, disposition_or_status, case_filed_date, case_type,judge_name, created_by, data_source_url, md5_hash)
SELECT 91, case_number, disposition, date_filed, case_type, judge_commissioner_assigned, created_by, data_source_url,
       md5(concat_ws('', 91, case_number, disposition, date_filed, case_type, judge_commissioner_assigned, created_by, data_source_url))
FROM usa_raw.mo_court_case_scrape;

# ACtivities

INSERT IGNORE INTO us_court_cases.old_court_case_activities
    (court_id, case_id, activity_decs, activity_date, created_by, md5_hash)
SELECT 91, case_number, case_activity, date, created_by,
       md5(concat_ws('', 91, case_number, case_activity, date, created_by)) AS md5_hash
       FROM usa_raw.mo_court_case_activity_scrape;


# party

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, created_by, md5_hash)
                SELECT 91, c.case_number, 0, c.petitioner_name, 'Petitioner', s.petitioner_address, c.petitioner_city, c.petitioner_state, c.petitioner_zip, s.data_source_url, s.created_by,
                       md5(concat_ws('', 91, c.case_number, 0, c.petitioner_name, 'Petitioner', s.petitioner_address, c.petitioner_city, c.petitioner_state, c.petitioner_zip, s.data_source_url, s.created_by))
                FROM usa_raw.mo_court_case_scrape_clear c
                JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, created_by, md5_hash)
    SELECT 91, c.case_number, 0, c.respondent_name, 'Respondent', s.respondent_address, c.respondent_city, c.respondent_state, c.respondent_zip, s.data_source_url, s.created_by,
           md5(concat_ws('', 91, c.case_number, 0, c.respondent_name, 'Respondent', s.respondent_address, c.respondent_city, c.respondent_state, c.respondent_zip, s.data_source_url, s.created_by))
    FROM usa_raw.mo_court_case_scrape_clear c
    JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id,is_lawyer, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, created_by, md5_hash)
SELECT 91, c.case_number, 0, c.plaintiff_name, 'Plaintiff', s.plaintiff_address, c.plaintiff_city, c.plaintiff_state, c.plaintiff_zip, s.data_source_url, s.created_by,
       md5(concat_ws('', 91, c.case_number, 0, c.plaintiff_name, 'Plaintiff', s.plaintiff_address, c.plaintiff_city, c.plaintiff_state, c.plaintiff_zip, s.data_source_url, s.created_by))
FROM usa_raw.mo_court_case_scrape_clear c
JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, party_city, party_state, party_zip, data_source_url, created_by, md5_hash)
SELECT 91, c.case_number,  0, c.defendant_name, 'Defendant', s.defendant_address, c.defendant_city, c.defendant_state, c.defendant_zip, s.data_source_url, s.created_by,
    md5(concat_ws('', 91, c.case_number,  0, c.defendant_name, 'Defendant', s.defendant_address, c.defendant_city, c.defendant_state, c.defendant_zip, s.data_source_url, s.created_by))
FROM usa_raw.mo_court_case_scrape_clear c
JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, data_source_url, created_by, md5_hash)
SELECT 91, c.case_number, 0, c.petitioner_attorney_name, 'Petitioner Attorney', s.petitioner_attorney_address, s.data_source_url, s.created_by,
       md5(concat_ws('', 91, c.case_number, 0, c.petitioner_attorney_name, 'Petitioner Attorney', s.petitioner_attorney_address, s.data_source_url, s.created_by))
FROM usa_raw.mo_court_case_scrape_clear c
JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, data_source_url, created_by, md5_hash)
SELECT 91, c.case_number,  0, c.respondent_attorney_name,'Respondent Attorney', s.respondent_attorney_address,  s.data_source_url, s.created_by,
       md5(concat_ws('', 91, c.case_number,  0, c.respondent_attorney_name,'Respondent Attorney', s.respondent_attorney_address,  s.data_source_url, s.created_by))
FROM usa_raw.mo_court_case_scrape_clear c
JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id,  is_lawyer, party_name, party_type, party_address, data_source_url, created_by, md5_hash)
SELECT 91, c.case_number,  0, c.plaintiff_attorney_name, 'Plaintiff Attorney', s.plaintiff_attorney_address, s.data_source_url, s.created_by,
       md5(concat_ws('', 91, c.case_number,  0, c.plaintiff_attorney_name, 'Plaintiff Attorney', s.plaintiff_attorney_address, s.data_source_url, s.created_by))
FROM usa_raw.mo_court_case_scrape_clear c
JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address,  data_source_url, created_by, md5_hash)
SELECT 91, c.case_number, 0, c.defendant_attorney_name, 'Defendant Attorney', s.defendant_attorney_address, s.data_source_url, s.created_by,
       md5(concat_ws('', 91, c.case_number, 0, c.defendant_attorney_name, 'Defendant Attorney', s.defendant_attorney_address, s.data_source_url, s.created_by))
FROM usa_raw.mo_court_case_scrape_clear c
JOIN usa_raw.mo_court_case_scrape s ON s.id = c.scrape_id;



INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, created_by, md5_hash)
SELECT 91, case_number, 0, party_name, type, party_address, created_by,
           md5(concat_ws('', 91, case_number, 0, party_name, type, party_address, created_by))
    FROM usa_raw.mo_court_case_scrape_parties;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_address, created_by, md5_hash)
SELECT 91, case_number, 1, attorney_name, type, attorney_address, created_by,
       md5(concat_ws('', 91, case_number, 1, attorney_name, type, attorney_address, created_by))
    FROM usa_raw.mo_court_case_scrape_parties;



# Jefferson County District Court (court_id = 89)

# info
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, created_by, data_source_url, md5_hash)
SELECT 89, case_number, date_received, case_type, created_by, url,
       md5(concat_ws('', 89, case_number, date_received, case_type, created_by, url))
           FROM usa_raw.jefferson_county_texas_court_case_scrape
where case_number is not null
;


# PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT 89, p.case_number,  p.party_name, p.party_type, c.created_by, c.url,
       md5(concat_ws('', 89, p.case_number,  p.party_name, p.party_type, c.created_by, c.url))
           FROM usa_raw.jefferson_county_texas_court_case_scrape_parties_clear p
           JOIN usa_raw.jefferson_county_texas_court_case_scrape c on c.case_number = p.case_number
           WHERE p.party_class!='Organization';

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id,case_id, party_name, law_firm, party_type, created_by, data_source_url, md5_hash)
SELECT 89, p.case_number,  p.party_name,p.party_name, p.party_type, c.created_by, c.url,
       md5(concat_ws('', 89, p.case_number,  p.party_name,p.party_name, p.party_type, c.created_by, c.url))
           FROM usa_raw.jefferson_county_texas_court_case_scrape_parties_clear p
           JOIN usa_raw.jefferson_county_texas_court_case_scrape c on c.case_number = p.case_number
           WHERE p.party_class='Organization' and c.case_number is not null;


# Activities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_type, activity_date, created_by, data_source_url, md5_hash)
SELECT 89, a.case_number, a.case_activity, a.date, a.created_by, c.url,
       md5(concat_ws('', 89, a.case_number, a.case_activity, a.date, a.created_by, c.url))
           FROM usa_raw.jefferson_county_texas_court_activity_scrape a
           JOIN usa_raw.jefferson_county_texas_court_case_scrape c on c.case_number = a.case_number
WHERE c.case_number is not null;




# Circuit Court of Cook County (court_id = 86)

# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,case_description, judge_name, created_by, data_source_url, md5_hash)
SELECT 86, c.case_number, c.filing_date, case_category, c.case_type, a.case_activity_judge, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, c.case_number, c.filing_date,case_category, c.case_type, a.case_activity_judge, c.created_by, c.data_source_url))
from il_raw.cook_county_court_case_scrape c
join il_raw.cook_county_court_case_activity_scrape a on a.case_number = c.case_number;


# Actitvities

INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_type, activity_date, created_by, data_source_url, md5_hash)
SELECT 86, a.case_number, a.case_activity, a.case_activity_date, a.created_by, c.data_source_url,
       md5(concat_ws('', 86, a.case_number, a.case_activity, a.case_activity_date, a.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_activity_scrape a
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = a.case_number;

#PARTY


# plaintiff Attorney
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id,is_lawyer, party_name,  law_firm, party_type, party_address, party_city, party_state, party_zip, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 1, a.name,a.company_name, 'Plaintiff Attorney', a.address, a.city, a.state, a.zip, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 1, a.name,a.company_name, 'Plaintiff Attorney', a.address, a.city, a.state, a.zip, c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
join il_raw.cook_county_court_attorneys a on p.plaintiff_attorney_id = a.id
JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;

#defendant attorney
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id,is_lawyer, party_name,  law_firm, party_type, party_address, party_city, party_state, party_zip, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 1, p.defendant_attorney_name,a.company_name, 'Defendant Attorney', a.address, a.city, a.state, a.zip, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 1, p.defendant_attorney_name,a.company_name, 'Defendant Attorney', a.address, a.city, a.state, a.zip, c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
         join il_raw.cook_county_court_attorneys a on p.defendant_attorney_name = a.name
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;

#defendant attorney (LIGHT)
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id,is_lawyer, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 1, p.defendant_attorney_name,'Defendant Attorney',  c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 1, p.defendant_attorney_name,'Defendant Attorney',  c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;


# plaintiff 1

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name,  party_type,law_firm, party_state, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 0, p.plaintiff_1, 'Plaintiff', p.pl_prod_plaintiff_1_org_name, p.plaintiff_1_state, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 0, p.plaintiff_1, 'Plaintiff', p.plaintiff_1_state, c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name,  party_type, party_state, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 0, p.plaintiff_2, 'Plaintiff', p.plaintiff_2_state, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 0, p.plaintiff_1, 'Plaintiff', p.plaintiff_1_state, c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;

# DEfendant

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name,  party_type,law_firm, party_state, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 0, p.defendant_1, 'Defendant', p.pl_prod_defendant_1_org_name, p.defendant_1_state, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 0, p.defendant_1, 'Defendant', p.pl_prod_defendant_1_org_name, p.defendant_1_state, c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name,  party_type, party_state, created_by, data_source_url, md5_hash)
SELECT 86, p.case_number, 0, p.defendant_2, 'Defendant', p.defendant_2_state, c.created_by, c.data_source_url,
       md5(concat_ws('', 86, p.case_number, 0, p.defendant_2, 'Defendant', p.defendant_2_state, c.created_by, c.data_source_url))
FROM il_raw.cook_county_court_case_clean_names p
         JOIN il_raw.cook_county_court_case_scrape c on c.case_number = p.case_number;



# Buck County Civil Court (Court_id = 101)

# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type,case_description, judge_name, status_as_of_date, created_by, data_source_url, md5_hash)
SELECT 101, case_number, date, case_type, remarks, judge,status, created_by, data_source_url,
       md5(concat_ws('', 101, case_number, date, case_type, remarks, judge,status, created_by, data_source_url))
from usa_raw.buck_county_civil_court_case_scrape
where case_number is not null;

# ACTIVITIES
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, created_by, data_source_url, md5_hash)
SELECT 101, a.case_number, a.case_activity, a.filing_date, a.created_by, a.data_source_url,
       md5(concat_ws('', 101, a.case_number, a.case_activity, a.filing_date, a.created_by, a.data_source_url))
FROM usa_raw.bucks_county_civil_court_case_activity_scrape a;


#PARTY

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name,  party_type, party_address, created_by, data_source_url, md5_hash)
SELECT 101, p.case_number, 0, p.name, CONCAT(UCASE(LEFT(p.role, 1)), SUBSTRING(p.role, 2)), p.address, p.created_by, p.data_source_url,
       md5(concat_ws('', 101, p.case_number, 0, p.name, p.role, p.address, p.created_by, p.data_source_url))
FROM usa_raw.buck_county_civil_court_case_parties p;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name,  party_type, created_by, data_source_url, md5_hash)
SELECT 101, p.case_number, 1, p.attorney, CONCAT(UCASE(LEFT(p.role, 1)), SUBSTRING(p.role, 2), ' Attorney'), p.created_by, p.data_source_url,
       md5(concat_ws('', 101, p.case_number, 1, p.attorney, CONCAT(UCASE(LEFT(p.role, 1)), SUBSTRING(p.role, 2), ' Attorney'), p.created_by, p.data_source_url))
FROM usa_raw.buck_county_civil_court_case_parties p
where p.attorney is not null;


# Buck County Court (Court_id = 102)


# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, judge_name, created_by, data_source_url, md5_hash)
SELECT 102, case_number, date_filed, case_type, judge_assigned, created_by, data_source_url,
       md5(concat_ws('', 102, case_number, date_filed, case_type, judge_assigned, created_by, data_source_url))
from usa_raw.bucks_county_court_scrape
where case_number is not null;

# ACTIVITIES
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_type, activity_date,activity_pdf, created_by, data_source_url, md5_hash)
SELECT 102, a.case_number, a.case_activity, a.date, a.pdf_url, a.created_by, c.data_source_url,
       md5(concat_ws('', 102, a.case_number, a.case_activity, a.date, a.pdf_url, a.created_by, c.data_source_url))
FROM usa_raw.bucks_county_court_case_activity_scrape a
         JOIN usa_raw.bucks_county_court_scrape c on c.case_number = a.case_number;



#PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name,  party_type, created_by, data_source_url, md5_hash)
SELECT 102, case_number, plaintiff_name, 'Plaintiff', created_by, data_source_url,
       md5(concat_ws('', 102, case_number, plaintiff_name, 'Plaintiff', created_by, data_source_url))
from usa_raw.bucks_county_court_scrape;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, party_name,  party_type, created_by, data_source_url, md5_hash)
SELECT 102, case_number, defendant_name, 'Defendant', created_by, data_source_url,
       md5(concat_ws('', 102, case_number, defendant_name, 'Defendant', created_by, data_source_url))
from usa_raw.bucks_county_court_scrape
where case_number is not null;


# Southern district of Illinois Court (99)
    #INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_name, judge_name, created_by, data_source_url, md5_hash)
SELECT DISTINCT 99, case_number, case_name, judge, created_by, src_url,
                md5(concat_ws('', 99, case_number, case_name, judge, created_by, src_url))
from il_raw.southern_district_of_illinois_court_docket_calendar;

    #PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT DISTINCT 99, case_number, 0, defendant_name, 'Defendant', created_by, src_url,
                md5(concat_ws('', 99, case_number, 0, defendant_name, 'Defendant', created_by, src_url))
from il_raw.southern_district_of_illinois_court_docket_calendar;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT DISTINCT 99, case_number, 0, plaintiff_name, 'Plaintiff', created_by, src_url,
                md5(concat_ws('', 99, case_number, 0, plaintiff_name, 'Plaintiff', created_by, src_url))
from il_raw.southern_district_of_illinois_court_docket_calendar;

    #ACTIVITIES
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_date, activity_decs, created_by, data_source_url, md5_hash)
SELECT DISTINCT 99, case_number, date, description, created_by, src_url,
                md5(concat_ws('', 99, case_number, date, description, created_by, src_url))
from il_raw.southern_district_of_illinois_court_docket_calendar;


# San Diego County Court (court_id = 103)

#INFO
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, created_by, data_source_url, md5_hash)
SELECT DISTINCT 103, case_number, date_file, case_type, created_by, data_source_url,
                md5(concat_ws('', 103, case_number, date_file, case_type, created_by, data_source_url))
from usa_raw.ca_san_diego_county_court_case_scrape;

#PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT DISTINCT 103, case_number, 0, case_defendent, 'Defendant', created_by, data_source_url,
                md5(concat_ws('', 103, case_number, 0, case_defendent, 'Defendant', created_by, data_source_url))
from usa_raw.ca_san_diego_county_court_case_scrape;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type, created_by, data_source_url, md5_hash)
SELECT DISTINCT 103, case_number, 0, case_plaintiff, 'Plaintiff', created_by, data_source_url,
                md5(concat_ws('', 103, case_number, 0, case_plaintiff, 'Plaintiff', created_by, data_source_url))
from usa_raw.ca_san_diego_county_court_case_scrape;



# Orange County Superior Court (court_id=92)

        # info
INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_filed_date, case_type, case_name, disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash)
SELECT 92, cs.case_number, cs.date_filed, cs.case_type, cl.case_desc, cs.disposition, cs.status, cs.judge, cl.src_url, cs.created_by,
       md5(concat_ws('',92, cs.case_number, cs.date_filed, cs.case_type, cl.case_desc, cs.disposition, cs.status, cs.judge, cl.src_url, cs.created_by ))
from usa_raw.orange_county_fl_court_case_scrape as cs
    join usa_raw.orange_county_fl_court_case_list as cl on cl.case_number = cs.case_number;

        # PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type,party_name, created_by, md5_hash)
select 92, 0, pc.case_number, pc.type, pc.name, p.created_by,
       md5(concat_ws('',92,0, pc.case_number, pc.type, pc.name, p.created_by))
from usa_raw.orange_county_fl_court_case_parties_clear as pc
    join usa_raw.orange_county_fl_court_case_scrape as p on p.case_number = pc.case_number;

INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, is_lawyer, case_id, party_type,party_name, created_by, md5_hash)
select 92, 1, pc.case_number, concat_ws(' ',pc.type,'Attorney') as case_type, pc.attorney, p.created_by,
       md5(concat_ws('',92,0, pc.case_number, concat_ws(' ',pc.type,'Attorney'), pc.attorney, p.created_by))
from usa_raw.orange_county_fl_court_case_parties_clear as pc
    join usa_raw.orange_county_fl_court_case_scrape as p on p.case_number = pc.case_number;
where pc.attorney is not null;


        # ACTIVITIES
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_decs, activity_date, activity_pdf, data_source_url, created_by, md5_hash)
select 92, case_number, case_activity, date, case_pdf_ref, case_link, created_by,
       md5(concat_ws('',92, case_number, case_activity, date, case_pdf_ref, case_link, created_by))
from usa_raw.orange_county_fl_court_case_activity;



# FL (court_id = 104)

# INFO

INSERT IGNORE INTO us_court_cases.old_court_case_info (court_id, case_id, case_name, case_filed_date, case_type,case_description, judge_name, status_as_of_date, created_by, md5_hash)
SELECT 104, case_number, caseStyle, case_filed_date, case_category_description, case_type_description, judge,case_status, created_by,
       md5(concat_ws('', 104, case_number, caseStyle, case_filed_date, case_category_description, case_type_description, judge,case_status, created_by))
from usa_raw.fl_13th_court_scrape;


# ACTIVITIES
INSERT IGNORE INTO us_court_cases.old_court_case_activities (court_id, case_id, activity_type, activity_date, activity_pdf, created_by, data_source_url, md5_hash)
SELECT 104, a.case_number, a.case_activity, a.date, a.pdf_local, a.created_by,src_url,
       md5(concat_ws('', 104, a.case_number, a.case_activity, a.date, a.pdf_local, a.created_by,src_url))
FROM usa_raw.fl_13th_case_activity_scrape a;


#PARTY
INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type,party_address, created_by, data_source_url, md5_hash)
                                        SELECT 104, case_number, 0, name, party_type, partyAddress, created_by, src_url,
                md5(concat_ws('', 104, case_number, 0, name, party_type, partyAddress, created_by, src_url))
from usa_raw.fl_13th_case_party;


INSERT IGNORE INTO us_court_cases.old_court_case_party (court_id, case_id, is_lawyer, party_name, party_type,party_address, party_description, created_by, data_source_url, md5_hash)
SELECT 104, case_number, 1, attorney_name, party_type, attorneyAddress, attorneyPhone, created_by, src_url,
       md5(concat_ws('', 104, case_number, 1, attorney_name, party_type, attorneyAddress, attorneyPhone, created_by, src_url))
from usa_raw.fl_13th_case_party;
