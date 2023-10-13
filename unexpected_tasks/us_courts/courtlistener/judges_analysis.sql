SELECT cc.court_id, cc.court_full_name, count(*) FROM cl_judge_info i
                                                          join cl_judge_job cjj on i.person_id = cjj.person_id
                                                          join cl_courts cc on cjj.court_id = cc.court_id
group by cc.court_id;