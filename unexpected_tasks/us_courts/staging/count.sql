# 1) Total cases in the raw data set now.
select count(*) from (SELECT * from us_courts.us_case_info group by case_id) info
select count(*) from (SELECT * from us_courts.us_saac_case_info group by case_id) info


# 2) Total cases in the staging data set now.

select count(*) from (SELECT * from us_courts_staging.cases group by id) info

# 3) Total judges in the database now
# 4) How many ONLY CIVIL cases are there now?

SELECT sum(total_civil) from us_courts_analysis.us_case_courthouse_counts
# 2376867


# 5) How many of these ONLY CIVIL cases have PDFs?
select court_id, count(*) from us_case_activities_pdf
where case_id in
      (SELECT case_id from us_courts.us_case_info where case_type not in ('CRIMINAL Miscellaneous','Petition on Criminal Case','Appeals - Criminal Other - Other Criminal','Appeals - Criminal Misdemeanor - Assault Related''Appeals - Criminal Misdemeanor - Domestic Violence','CRIMINAL, EXPEDITED','Appeals - Criminal Felony - Weapons Related','MUNI CRIMINAL TRAFFIC','CRIMINAL','Criminal-Clerk', 'Domestic Family', 'Matrimonial - Contested', 'CHILD SUPPORT', 'Paternity', 'FAMILY', 'FAMILY, EXPEDITED', 'Other Matters - Application to Docket ', 'Family Court Judgment','Child Support - Agency','UIFSA - Uniform Interstate Family Support Act','Appeals - Family - Domestic Relations','Appeals - Family - Domestic Violence','Paternity / Parentage - Agency'))
group by court_id

# 294399    #317+1026+81708+85668+637+62509+62534=

# 6) How many of these ONLY CIVIL cases have been categorized with three-tier system?



