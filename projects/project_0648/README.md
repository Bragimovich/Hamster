**Owner**: Muhammad Qasim

**Scrape instruction**:  https://lokic.locallabs.com/scrape_tasks/648

**Dataset**:  db01.us_court_cases.fl_occc_case_activities,
              db01.us_court_cases.fl_occc_case_info,
              db01.us_court_cases.fl_occc_case_party,
              db01.us_court_cases.fl_occc_case_pdfs_on_aws,
              db01.us_court_cases.fl_occc_case_relations_activity_pdf,
              db01.us_court_cases.fl_occc_case_runs,
           

**Run commands**:  hamster grab 648 --mqasim --download
                   hamster grab 648 --mqasim --store
                   hamster grab 648 --mqasim --cron
