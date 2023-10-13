**Owner**: Umar Farooq

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/744

**Dataset**: db01.state_salaries__raw.ks_employee_salaries
             db01.state_salaries__raw.ks_employee_salaries_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0744 --debug --download
                     : bundle exec ruby hamster.rb --grab=0744 --debug --store

**Run commands Docker**: hamster grab 744 --download
                       : hamster grab 744 --store

_May_ 2023_
