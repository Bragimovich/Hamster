**Owner**: Abdul Wahab
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/590

**Dataset**: Db01.us_court_cases.de_sc_case_activities,
             Db01.us_court_cases.de_sc_case_additional_info,
             Db01.us_court_cases.de_sc_case_info,
             Db01.us_court_cases.de_sc_case_party,
             Db01.us_court_cases.de_sc_case_pdfs_on_aws,
             Db01.us_court_casesde_sc_case_relations_activity_pdf
             Db01.us_court_cases.de_sc_case_runs

**Run commands**: ruby hamster.rb --grab=590 --download
                  ruby hamster.rb --grab-590 --download_pdfs
                  ruby hamster.rb --grab=590 --store

_February 2023_
