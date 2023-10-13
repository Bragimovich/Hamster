**Owner**: Bhawna Pahadiya
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/585

**Dataset**:
  - db01.obituary.raw_tributearchive
  - db01.obituary.raw_tributearchive_ceo_settings
  - db01.obituary.raw_tributearchive_funeral_home
  - db01.obituary.tribalarchive_problem_persons
  - db01.obituary.tributearchive_settings
  - db01.obituary.raw_tributearchive_runs

**Run commands**:
- Ruby (Only local)
  - bundle exec ruby hamster.rb --grab=0585 --debug --type=odd
  - bundle exec ruby hamster.rb --grab=0585 --debug --type=even
  - bundle exec ruby hamster.rb --grab=0585 --weekly_download --debug
- Docker
  - hamster grab 585 --type=odd
  - hamster grab 585 --type=even --clone 1

_February 2023_
