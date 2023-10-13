select ggg.court_id, count(*) from (SELECT c.id,c.court_id, act.pdf, l.first_name,l.picture, j.first_name j_first_name, j.picture judge_picture FROM cases c
    join cases_lawyers cl on c.id = cl.case_id
    join lawyers l on cl.lawyer_id = l.id
    join lawyers_law_schools lls on l.id = lls.lawyer_id
    join lawyers_universities lu on l.id = lu.lawyer_id
    join cases_judges cj on c.id = cj.case_id
    join judges j on cj.judge_id = j.id
    join judges_law_schools jls on j.id = jls.judge_id
    join judges_universities ju on j.id = ju.judge_id
    join activities act on c.id = act.case_id
where act.pdf!=''
group by c.id) ggg
group by ggg.court_id;

SELECT * from
(SELECT c.id, c.court_id, c2.name court_name, c.raw_id, c.name, c.type, c.category, act.pdf, concat_ws(' ',j.first_name, j.last_name, j.middle_name) judge_name,  j.picture judge_picture, j.data_source_url judge_bio, concat_ws(' ',l.first_name,l.middle_name, l.last_name) lawyer_name, l.picture lawyer_picture, l.data_source_url lawyer_bio,
       @rn := IF(@prev = c.court_id, @rn + 1, 1) AS rn,
       @prev := c.court_id

       FROM cases c
    join cases_lawyers cl on c.id = cl.case_id
    join lawyers l on cl.lawyer_id = l.id
    join lawyers_law_schools lls on l.id = lls.lawyer_id
    join lawyers_universities lu on l.id = lu.lawyer_id
    join cases_judges cj on c.id = cj.case_id
    join judges j on cj.judge_id = j.id
    join judges_law_schools jls on j.id = jls.judge_id
    join judges_universities ju on j.id = ju.judge_id
    join activities act on c.id = act.case_id
           join courts c2 on c.court_id = c2.id
    JOIN (SELECT @prev := NULL, @rn := 0) AS vars


    group by c.id) tt
WHERE tt.rn <= 10

