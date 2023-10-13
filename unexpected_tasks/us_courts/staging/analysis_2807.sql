# How many uncategorized cases have PDFs or text that we tried matching to, but failed to match?

SELECT count(*) FROM (SELECT count(*) FROM us_courts_staging.cases
join us_courts_staging.activities a on cases.id = a.case_id
where cases.type is null and summary_pdf is not null and a.pdf is not null
group by raw_id) af;

# 23'106

SELECT count(*) FROM us_courts_staging.cases
where cases.type is null and (id in (select distinct case_id from us_courts_staging.activities where pdf is not null)
or summary_pdf is not null);

#

# How many uncategorized cases have PDFs or text that we have NOT tried matching to, yet?

SELECT count(*) FROM us_courts_staging.cases
where cases.type is null and summary_pdf is not null and summary_text is null;

# SELECT count(*) FROM us_courts_staging_working_copy.cases where type is null and summary_pdf is not null and summary_text is null
# # 160'774
#
# SELECT count(*) FROM (SELECT count(*) FROM us_courts_staging.cases
#                                                join us_courts_staging.activities a on cases.id = a.case_id
#                       where cases.type is null and summary_pdf is not null and a.pdf is not null and summary_text is null
#                       group by raw_id) af;
#
# SELECT count(*) FROM us_courts_staging.cases
# where id in (select distinct case_id from us_courts_staging.activities where pdf is not null)
#   and summary_pdf is not null and summary_text is null;

#     How many uncategorized cases do not have PDFs or text to match to?

SELECT count(*) FROM us_courts_staging.cases
where cases.type is null and summary_pdf is null and id not in (select distinct case_id from us_courts_staging.activities where pdf is not null);

# 4'925'907

# SELECT count(SELECT count(*) FROM us_courts_staging.cases
#              where cases.type is null and summary_pdf is null and id not in
#                                                                   (SELECT case_id from us_courts_staging.activities WHERE pdf is not null) group by raw_id);

# Of these cases, how many have a case description or raw type?

SELECT count(*) FROM us_courts_staging.cases
where cases.type is null and summary_pdf is null and id not in (select distinct case_id from us_courts_staging.activities where pdf is not null)
and (cases.description is not null or cases.raw_type is not null);

SELECT count(*) FROM us_courts_staging.cases
                         join us_courts_staging.activities a on cases.id = a.case_id
where cases.type is null and summary_pdf is null and a.pdf is null
  and cases.description is not null and cases.raw_type is not null;

# 943770 – Description is not null
# 595397 – Description and raw_type is not null




# How many uncategorized cases come from appeals courts and supreme courts?

SELECT COUNT(*) FROM us_courts_staging.cases
WHERE type is null and  court_id IN (SELECT id FROM us_courts_staging.courts
                   WHERE sub_type = 'Court of Appeals' or sub_type = 'Supreme Court');

# 81758

# How many uncategorized cases were added to the data set in the past 3 months?

select count(*) from (SELECT COUNT(*) FROM us_courts_staging.cases
WHERE type is null and filled_date>'2021-04-28'
group by raw_id) ff;

# 115,539

# Total, how many uncategorized cases have either (1) raw type, (2) pdfs or text to match to, or (3) case description text?
select count(*) from us_courts_staging.cases
    where type is null and
          (raw_type is not null or description is not null or summary_text is not null
               or complaint_text is not null or appeal_text is not null
                                or id in (select distinct case_id from us_courts_staging.activities where pdf is not null));

# 566258



SELECT count(*) from us_courts_staging.cases where type is nullЖ




#