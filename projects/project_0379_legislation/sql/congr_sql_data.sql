


SELECT congress_number, substr(congress_number,1,3) from congressional_legislation_info limit 20

UPDATE usa_raw.congressional_legislation_info set congress = substr(congress_number,1,3)
UPDATE usa_raw.congressional_legislation_info SET md5_hash = MD5(concat_ws('',leg_id, congress, congress_number, sponsor_link, sponsor_name, sponsor_id, status, short_description))

UPDATE usa_raw.congressional_legislation_actions set congress = substr(data_source_url,31,3);
UPDATE IGNORE usa_raw.congressional_legislation_actions SET md5_hash = MD5(concat_ws('',leg_id, congress, DATE_FORMAT(date, '%Y-%m-%dT%h:%m:%s+00:00'),  action_by, action_text));

UPDATE usa_raw.congressional_legislation_actions_overview set congress = substr(data_source_url,31,3)
UPDATE IGNORE usa_raw.congressional_legislation_actions_overview SET md5_hash = MD5(concat_ws('',leg_id, congress,  date, action_text))

UPDATE usa_raw.congressional_legislation_cosponsors set congress = substr(data_source_url,31,3);
UPDATE IGNORE usa_raw.congressional_legislation_cosponsors SET md5_hash = MD5(concat_ws('',leg_id, congress, name, date, sponsor_id, link));

UPDATE usa_raw.congressional_legislation_committees set congress = substr(data_source_url,31,3);
UPDATE IGNORE usa_raw.congressional_legislation_committees SET md5_hash = MD5(concat_ws('',leg_id, congress, committee, date, activity, related));

UPDATE usa_raw.congressional_legislation_related_bills set congress = substr(data_source_url,31,3);
UPDATE IGNORE usa_raw.congressional_legislation_related_bills SET md5_hash = MD5(concat_ws('',leg_id, congress, date, link, bill_id, title, relations_HR6000, relations_identified, latest_action));

UPDATE usa_raw.congressional_legislation_subjects set congress = substr(data_source_url,31,3);
UPDATE IGNORE usa_raw.congressional_legislation_subjects SET md5_hash = MD5(concat_ws('',leg_id, congress, link, subject_name));

UPDATE usa_raw.congressional_legislation_texts set congress = substr(data_source_url,31,3);
UPDATE usa_raw.congressional_legislation_texts set congress = substr(data_source_url,31,3) where congress=0;
UPDATE IGNORE usa_raw.congressional_legislation_texts SET md5_hash = MD5(concat_ws('',leg_id, congress, pdf_link));




select q.pdf_id from congressional_legislation_texts clt
                         join (select max(id) pdf_id, pdf_link, aws_link, count(*) ccc from congressional_legislation_texts  where congress=117 group by pdf_link order by ccc desc limit 1000) q
                              on clt.id = q.pdf_id
WHERE clt.aws_link is null