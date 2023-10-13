**Owner**: Danil Kurshanov
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/634

**Dataset**:

    - db01.us_court_cases.la_1c_ac_case_info
    - db01.us_court_cases.la_1c_ac_case_activities
    - db01.us_court_cases.la_1c_ac_case_party
    - db01.us_court_cases.la_1c_ac_case_pdfs_on_aws
    - db01.us_court_cases.la_1c_ac_case_relations_activity_pdf
    - db01.us_court_cases.la_1c_ac_case_runs

**Run commands**:

- Ruby (Only local)
    - bundle exec ruby hamster.rb --grab=0634 --debug --download # Download pdf file and safe in "#{storehouse}/store/.."
    - bundle exec ruby hamster.rb --grab=0634 --debug --store    # Parse pdf file
- Docker
    - hamster grab 634 --download
    - hamster grab 634 --store

_May 2023_
