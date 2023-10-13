update us_courts_analysis.us_case_courthouse_counts uccc
    join us_courts.us_courts_table uct on uccc.court_id=uct.court_id
    SET uccc.court_name = uct.court_name, uccc.court_state= uct.court_state;