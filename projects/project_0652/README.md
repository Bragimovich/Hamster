**Owner**: Jaffar Hussain
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/652

**Dataset**: 
db01.us_court_cases.fl_ccsjcpc_case_activities
db01.us_court_cases.fl_ccsjcpc_case_party
db01.us_court_cases.fl_ccsjcpc_case_info
db01.us_court_cases.fl_ccsjcpc_case_pdfs_on_aws
db01.us_court_cases.fl_ccsjcpc_case_relations_activity_pdf
db01.us_court_cases.fl_ccsjcpc_case_runs

**Run commands**: 
hamster grab 652 --auto
hamster grab 652 --download
hamster grab 652 --store

**Download old data**
hamster grab 652 --download --start_date=01/01/2018 --end_date=12/31/2018