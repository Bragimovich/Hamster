**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/360

**Dataset**:
    - db01.usa_raw.wi_campaign_finance_contributors
    - db01.usa_raw.wi_campaign_finance_expenditures
    - db01.usa_raw.wi_campaign_finance_committees
    - db01.usa_raw.wi_campaign_finance_runs

**Run commands**:
- Ruby(options: 'letter' or 'range')
  - bundle exec ruby hamster.rb --grab=0360 --debug --csv
  - bundle exec ruby hamster.rb --grab=0360 --debug --pdf --first_block
  - bundle exec ruby hamster.rb --grab=0360 --debug --pdf --second_block
- Docker
  - hamster grab 360 --agegic --csv --agegic
  - hamster grab 360 --agegic --pdf --first_block --clone 1 --agegic
  - hamster grab 360 --agegic --pdf --second_block --clone 2 --agegic

_July 2023_
