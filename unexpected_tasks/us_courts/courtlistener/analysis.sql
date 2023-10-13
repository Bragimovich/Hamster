
SELECT ccc.court_id, ds.court_id, ccc.court_full_name, count(*) from cl_csv_dockets ds
                                                                         join cl_courts_clean ccc on ds.court_id = ccc.cl_court_id
where ccc.court_id is not null
  and ccc.court_id not in (SELECT distinct court_id from us_case_info where created_at > '2023-01-01')
  and ccc.court_id not in (SELECT distinct court_id from us_saac_case_info where created_at > '2023-01-01')
group by ccc.court_id;



SELECT  ccc.court_id, ds.case_name, ds.docket_number, date_filed,
        ds.court_id, cause, nature_of_suit, appellate_fee_status,

from us_courts.cl_csv_dockets ds
    join us_courts.cl_courts_clean ccc on ds.court_id = ccc.cl_court_id
where ccc.court_id is not null
  and ds.court_id in ('mssd','msnd','njd','alnd','alsd','gand','gamd','gasd','nyed','nywd','dcd','scd','ohsd','ohnd','tnmd','tned','tnwd','miwd','mied')
  and ds.docket_number not in (SELECT case_id from us_courts.us_case_info where court_id in (4,5,7,9,10,14,15,16,25,26,29,33,36,37,43,44,45,50,51))



SELECT ccc.court_id, ds.court_id, ccc.court_full_name from us_courts.cl_csv_dockets ds
                                                                         join us_courts.cl_courts_clean ccc on ds.court_id = ccc.cl_court_id
where ccc.court_id is not null
  and ccc.court_id in (SELECT court_id from us_courts.us_courts_table where is_pacer=1)
  and ds.docket_number not in (SELECT case_id from us_courts.us_case_info
                           where court_id in (4,5,7,9,10,14,15,16,25,26,29,33,36,37,43,44,45,50,51));

SELECT  ccc.court_id, ds.case_name, ds.docket_number, date_filed,
        ds.court_id, cause, nature_of_suit, appellate_fee_status,
from us_courts.cl_csv_dockets ds
         join us_courts.cl_courts_clean ccc on ds.court_id = ccc.cl_court_id
join
where ccc.court_id is not null