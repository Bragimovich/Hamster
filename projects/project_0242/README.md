**Owner**: Ray Piao
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/242

**Dataset**:

    - db01.usa_raw.michigan_campaign_finance_candidates
    - db01.usa_raw.michigan_campaign_finance_committees
    - db01.usa_raw.michigan_campaign_finance_contributions
    - db01.usa_raw.michigan_campaign_finance_contributors
    - db01.usa_raw.michigan_campaign_finance_expenditures
    - db01.usa_raw.michigan_campaign_finance_runs

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0242 --debug [ --buffer=max_buffer_size ] [ --skipdelete ] [ --startyear=start_fiscal_year ]
- Docker
  - hamster grab 242 [ --buffer=max_buffer_size ] [ --skipdelete ] [ --startyear=start_fiscal_year ]

_July 2023_
