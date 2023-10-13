create table us_courts_analysis.litigation_case_type__IRL
(
    id                  bigint auto_increment
        primary key,
    `values`            varchar(1023)                                                                                                               null,
    priority            varchar(255)                                                                                                                null,
    general_category    varchar(255)                                                                                                                null,
    midlevel_category   varchar(255)                                                                                                                null,
    specific_category   varchar(255)                                                                                                                null,
    additional_category varchar(255)                                                                                                                null,
    source_spreadsheet  varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null
)
    collate = utf8mb4_unicode_520_ci;



use us_courts_analysis;
INSERT INTO analysis_litigation_IRL_types__courthouses (court_id, case_type, count, priority, general_category,midlevel_category, specific_category, additional_category )
SELECT court_id, case_type, count, type_r.priority, type_r.general_category, type_r.midlevel_category, type_r.specific_category, type_r.additional_category from
    (select court_id, case_type, count(*) count from us_courts.us_case_info group by court_id, case_type) as type_counts
        join us_courts_analysis.litigation_case_type__IRL as type_r on type_counts.case_type = type_r.values;




UPDATE analysis_litigation_IRL_types__courthouses
SET midlevel_category = SUBSTRING_INDEX(midlevel_category, ' - ', -1)
UPDATE analysis_litigation_IRL_types__courthouses
SET specific_category = SUBSTRING_INDEX(specific_category, ' - ', -1)
UPDATE analysis_litigation_IRL_types__courthouses
SET additional_category = SUBSTRING_INDEX(additional_category, ' - ', -1)



UPDATE us_courts_analysis.analysis_litigation_IRL_types__pdfs irl
JOIN us_courts.us_case_activities_pdf pdf on irl.activity_id = pdf.activity_id
SET irl.link_pdf = pdf.file

SELECT link_pdf, replace(link_pdf, ' ', '%20') from analysis_litigation_IRL_types__pdfs


UPDATE analysis_litigation_IRL_types__pdfs
SET link_pdf = replace(link_pdf, ' ', '%20')
where court_id=35



SELECT * FROM analysis_litigation_IRL_types__pdfs WHERE top5_matches!='[]'


SELECT t.*
FROM analysis_litigation_IRL_types__pdfs as t,
     (SELECT ROUND((SELECT MAX(id) FROM analysis_litigation_IRL_types__pdfs) * RAND()) AS rnd
      FROM analysis_litigation_IRL_types__pdfs LIMIT 6000) AS tmp
WHERE t.id IN (rnd)
