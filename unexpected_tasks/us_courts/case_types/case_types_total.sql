# 1) Total "Only CIVIL" cases in the data set.

SELECT count(*) FROM us_courts.us_case_info WHERE case_type='CIVIL' or case_type='civil' or case_type='Civil'

# 2) Total "Only CIVIL" cases in the data set where we matched at least 1 keyword for categorization.

SELECT count(*) from (SELECT uci.case_id, uci.case_type, count(*) FROM us_courts_analysis.analysis_litigation_IRL_types__pdfs keyw
                                                                           JOiN us_courts.us_case_info uci on uci.case_id = keyw.case_id
                      WHERE uci.case_type = 'CIVIL' and keyw.top5_matches!='[]'
                      group by uci.case_id) o
# 2b) Total cases in the data set where we matched at least 1 keyword for categorization.

SELECT count(*) from (SELECT case_id, count(*) FROM us_courts_analysis.analysis_litigation_IRL_types__pdfs
where top5_matches!='[]' group by case_id) o

# 3) Total "Only CIVIL" cases in the data set that are from appellate or supreme courts.

SELECT count(*) FROM us_courts.us_saac_case_info WHERE case_type='CIVIL' or case_type='civil' or case_type='Civil'

# 4) Total "NULL" case type cases in the data set.
SELECT count(*) FROM us_courts.us_case_info WHERE case_type is null;


# 5) Total "NULL" case type cases in the data set where we matched at least 1 keyword for categorization.

SELECT count(*) from (SELECT uci.case_id, uci.case_type, count(*) FROM us_courts_analysis.analysis_litigation_IRL_types__pdfs keyw
                                                                           JOiN us_courts.us_case_info uci on uci.case_id = keyw.case_id
                      WHERE uci.case_type is null and keyw.top5_matches!='[]'
                      group by uci.case_id) o

# 6) Total "NULL" case type cases in the data set that are from appellate or supreme courts.

SELECT count(*) FROM us_courts.us_saac_case_info WHERE case_type is null
