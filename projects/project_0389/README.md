**Owner**: Eldar Eminov
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/389

**Dataset**: 

db01.us_court_cases.pa_sc_case_info
db01.us_court_cases.pa_sc_case_party
db01.us_court_cases.pa_sc_case_activities
db01.us_court_cases.pa_sc_case_pdfs_on_aws
db01.us_court_cases.pa_sc_case_relations_info_pdf
db01.us_court_cases.pa_sc_case_additional_info
db01.us_court_cases.pa_sc_case_consolidations
db01.us_court_cases.pa_sc_case_runs

**Run commands**: 

bundle exec ruby hamster.rb --grab=0389 --download

bundle exec ruby hamster.rb --grab=0389 --store

_March 2022_
