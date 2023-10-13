**Owner**: Umar Farooq

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/646

**Dataset**: db01.us_court_cases.mo_cc_case_info
             db01.us_court_cases.mo_cc_case_activities
             db01.us_court_cases.mo_cc_case_party
             db01.us_court_cases.md_dccc_case_judgment
             db01.us_court_cases.mo_cc_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0646 --debug --download
                     : bundle exec ruby hamster.rb --grab=0646 --debug --store

**Run commands Docker**: hamster grab 646 --download
                       : hamster grab 646 --store

_June_ 2023_
