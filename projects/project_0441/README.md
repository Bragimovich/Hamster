**Owner**: Igor Sas
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/441

**Dataset**: 

    db01.us_court_cases.da_tx_case_activities
    db01.us_court_cases.da_tx_case_info
    db01.us_court_cases.da_tx_case_party
    db01.us_court_cases.da_tx_case_pdfs_on_aws
    db01.us_court_cases.da_tx_case_relations_activity_pdf

**Run commands**:

    hamster grab 441
    hamster grab 441 --store
    hamster grab 441 --download
    hamster grab 441 --store --year=2021
    hamster grab 441 --download --format='TX' 
    hamster grab 441 --format='TX' --year=2020


