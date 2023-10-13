**Owner**: Adeel
 
**Scrape instruction**:
            https://lokic.locallabs.com/scrape_tasks/405

**Dataset**
            db01.us_court_cases.dc_ac_case_info
            db01.us_court_cases.dc_ac_case_party
            db01.us_court_cases.dc_ac_case_activities
            db01.us_court_cases.dc_ac_case_additional_info
            db01.us_court_cases.dc_ac_case_consolidations
            db01.us_court_cases.dc_ac_case_pdfs_on_aws
            db01.us_court_cases.dc_ac_case_relations_activity_pdf
            db01.us_court_cases.dc_ac_case_relations_info_pdf

**Run commands**: 
            bundle exec ruby hamster.rb --grab=0405 --download
            bundle exec ruby hamster.rb --grab=0405 --store

_May 2022_
