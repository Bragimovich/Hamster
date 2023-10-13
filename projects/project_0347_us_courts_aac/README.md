**Owner**: Alim Lumanov
 
**Scrape instruction**:

* https://lokic.locallabs.com/scrape_tasks/347#scrapeEvaluationDoc

**Dataset**:

* db01.us_court_cases.aac_case_activities
* db01.us_court_cases.aac_case_additional_info
* db01.us_court_cases.aac_case_complaint
* db01.us_court_cases.aac_case_consolidations
* db01.us_court_cases.aac_case_info
* db01.us_court_cases.aac_case_party
* db01.us_court_cases.aac_case_pdfs_on_aws
* db01.us_court_cases.aac_case_relations_activity_pdf
* db01.us_court_cases.aac_case_relations_info_pdf
* db01.us_court_cases.aac_case_runs

**Run commands**:

* bundle exec ruby hamster.rb --grab=0347 --download
* bundle exec ruby hamster.rb --grab=0347 --store
* bundle exec ruby hamster.rb --grab=0347 --auto
* bundle exec ruby hamster.rb --grab=0347 --update

_February 2022_
