UPDATE usa_raw.us_case_info
SET deleted = 1
WHERE id in
      (SELECT ids FROM (SELECT min(id) ids, court_id, md5_hash, count(*) cc, case_id from usa_raw.us_case_info
                        where deleted=0
                        group by md5_hash) tt
       where tt.cc>1);