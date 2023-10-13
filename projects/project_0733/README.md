**Owner**: Umar Farooq

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/733

**Dataset**: db01.state_salaries__raw.ny_public_salaries
             db01.state_salaries__raw.ny_public_salaries_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0733 --debug --download
                     : bundle exec ruby hamster.rb --grab=0733 --debug --store

**Run commands Docker**: hamster grab 733 --download
                       : hamster grab 733 --store

_June_ 2023_
