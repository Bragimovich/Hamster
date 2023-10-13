**Owner**: Umar Farooq

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/774

**Dataset**: db01.state_salaries__raw.ks_cc_employee_salaries
             db01.state_salaries__raw.ks_k12_employee_salaries
             db01.state_salaries__raw.ks_k12_employee_salaries_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0774 --debug --download
                     : bundle exec ruby hamster.rb --grab=0774 --debug --store

**Run commands Docker**: hamster grab 774 --download
                       : hamster grab 774 --store

_May_ 2023_
