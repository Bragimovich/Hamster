
# a. How many uncategorized cases have PDFs or text that we tried matching to, but failed to match?

SELECT count(*) FROM us_courts_staging.cases
where cases.type is null and (id in (select distinct case_id from us_courts_staging.activities where pdf is not null)
    or summary_pdf is not null) and filled_date>'2020-01-01';


# c. How many uncategorized cases do not have PDFs or text to match to?

SELECT count(*) FROM us_courts_staging.cases
where cases.type is null and summary_pdf is null and id not in (select distinct case_id from us_courts_staging.activities where pdf is not null) and filled_date>'2020-01-01';

# Of these cases, how many have a case description or raw type?
SELECT count(*) FROM us_courts_staging.cases
        where cases.type is null and summary_pdf is null and id not in (select distinct case_id from us_courts_staging.activities where pdf is not null)
          and (cases.description is not null or cases.raw_type is not null) and filled_date>'2020-01-01';



# d. How many uncategorized cases come from appeals courts and supreme courts?
SELECT COUNT(*) FROM us_courts_staging.cases
    WHERE type is null and  court_id IN (SELECT id FROM us_courts_staging.courts
    WHERE sub_type = 'Court of Appeals' or sub_type = 'Supreme Court') and filled_date>'2020-01-01';

# e. How many uncategorized cases were added to the data set in the past 3 months?

SELECT count(*) from (SELECT COUNT(*) FROM us_courts_staging.cases
                      WHERE type is null and filled_date>'2021-04-28'
                      group by raw_id) ff;


# f. Total, how many uncategorized cases have either (1) raw type, (2) pdfs or text to match to, or (3) case description text?
select count(*) from us_courts_staging.cases where type is null and (raw_type is not null or description is not null or summary_text is not null or complaint_text is not null or appeal_text is not null)
                                               and filled_date>'2020-01-01';


