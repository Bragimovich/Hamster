**Owner**: Raza
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/544

**Dataset**: db01.us_court_cases.ut_saac_case_info
             db01.us_court_cases.ut_saac_case_party
             db01.us_court_cases.ut_saac_case_activities
             db01.us_court_cases.ut_saac__case_pdfs_on_aws
             db01.us_court_cases.ut_saac__case_relations_info_pdf
             db01.us_court_cases.ut_saac_case_runs
             db01.us_court_cases.ut_saac_case_additional_info

**Run commands**: bundle exec ruby hamster.rb --grab=0544 --debug --download
                  bundle exec ruby hamster.rb --grab=0544 --debug --activity_page
                  bundle exec ruby hamster.rb --grab=0544 --debug --store
                  bundle exec ruby hamster.rb --grab=0544 --debug --activity_page_store

_January 2023_
