**Owner**: Maxim G
 
**Scrape instruction**: 

Scraper for NY supreme courts from site:
https://iapps.courts.state.ny.us/nyscef/CaseSearch?TAB=courtDateRange

The site has captcha and block for browser without JS.


**Dataset**: 

db01.us_court_cases.NY_case_*

**Run commands**: ...

For updating:

`hamster grab 172 --update`  – get cases for each court 3 days ago

`hamster grab 172 --old_amount=upd` – check active cases (update_at – 30 days ago)

`hamster grab 172 --old_amount=3` - redownload cases without case_id (bad case_id)

`hamster grab 172 --old_amount=1` – redownload old cases from __usa_raw.us_case_info__ table
`hamster grab 172 --old_amount=2` – redownload old cases from this table
 