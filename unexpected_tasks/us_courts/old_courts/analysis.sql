-- Staging how many cases in staging table
USE us_courts_staging;
SELECT cases.court_id, c.name, count(*) from cases
                                                 join courts c on cases.court_id = c.id
where court_id in (170,172, 173, 165,169, 171, 198, 181, 174, 175, 192, 186, 196, 183, 184)
group by court_id;


# Raw data

use us_courts;
SELECT i.court_id, ct.court_name, count(*) from us_courts.us_case_info i
    join us_courts.us_courts_table ct on i.court_id = ct.court_id
where i.court_id in (72, 74, 75, 70, 71, 73, 104, 86, 80, 81, 97, 91, 102, 88, 89)
group by i.court_id;


SELECT i.court_id,  count(*) from us_court_cases.old_court_case_info i
group by i.court_id;




# What's not in raw_table

SELECT i.court_id,  count(*) from us_court_cases.old_court_case_info i
where i.court_id in (SELECT i.court_id from us_courts.us_case_info i group by i.court_id)
group by i.court_id;






-- staging court_id:
--
-- Madison County Court – 			170	– 72
-- Lake County, IL Court 		– 172	– 74
-- Will County, IL Court
-- DupAGE  					– 173	–	75
-- Philadelphia Court (here) 	– 165	–	70
-- Delaware (here) 			– 169	–	71
-- Dallas, TX (here)			– 171	– 	73
--
--
-- The 9th Florida Circuit Court
-- The 13th Florida Circuit Court 	198 –	104
-- Cook County 		181		– 	86
-- St. Clair County – 	174	 	– 	80
-- Alameda 			175		– 	81
-- San Francisco		192		–	97
-- St. Louis			186		–	91
-- Bucks				196		–	102
-- Harris				183		– 	88
-- Jefferson 			184		–	89



# GET PROBLEM courts

SELECT p.court_id, o.cou-count(*) party_count, act.count activities_count, info.count info_count from us_courts.us_case_party p
    join (SELECT court_id, count(*) cou from us_court_cases.old_court_case_party group by court_id) o on o.court_id = p.court_id

    join (SELECT i.court_id, o.cou-count(*) count from us_courts.us_case_activities i
            join (SELECT court_id, count(*) cou from us_court_cases.old_court_case_activities group by court_id) o on o.court_id = i.court_id
            where i.court_id > 79 and i.court_id<150
            group by i.court_id) act on act.court_id = p.court_id

    join (SELECT i.court_id, o.cou-count(*) count from us_courts.us_case_info i
            join (SELECT court_id, count(*) cou from us_court_cases.old_court_case_info group by court_id) o on o.court_id = i.court_id
            where i.court_id > 79 and i.court_id<150
            group by i.court_id) info on info.court_id = p.court_id

where p.court_id > 79 and p.court_id<150
group by p.court_id




SELECT court_id, count(*) from us_court_cases.old_court_case_party group by court_id