# Cases in Phase 2 courts

SELECT cases.court_id, c.name, c.type, c.sub_type, count(*) from cases
  join courts c on cases.court_id = c.id
        and c.external_id in (301,403,302,404,405,303,406,304,407,408,409,410,411,412,305,413,306,307,414,12,18,441,308,57,310,422,423,424,425,426,427,314,315,428,429,430,436,432,435,433,434,319,58,53,322,439,323,440,442,443,444,326,329,332,22,446,335,447,448,449,450,451,452,453,454,455,456,457,458,8,460,461,339,339,340,246,462,342,97,11,17,1,341,42,42,474,475,476,477,478,466,467,468,469,470,471,472,473,474,344,405,2,481,544,544,346,466,482,483,484,349,485,350,351,331,328,445)
group by court_id;



# Cases for all courts


SELECT cases.court_id, c.name, c.type, c.sub_type, count(*) from cases
                                                                     join courts c on cases.court_id = c.id
group by court_id;



# lawyers phase 2
SELECT last_name, first_name, count(*) from lawyers
    join cases_lawyers cl on lawyers.id = cl.lawyer_id
WHERE external_table!='us_case_party_lawyers_unique'
    group by lawyers.id

