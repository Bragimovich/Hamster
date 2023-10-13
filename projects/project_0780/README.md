**Owner**: Hassan Nawaz

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/780

**Dataset**: db01.raw_contributions.ny_nyccfb_contributions
             db01.raw_contributions.ny_nyccfb_expenditures
             db01.raw_contributions.ny_nyccfb_intermediaries
             db01.raw_contributions.ny_nysboe_filers
             db01.raw_contributions.ny_nysboe_reports
             db01.raw_contributions.ny_nysboe_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0780 --debug --download
                     : bundle exec ruby hamster.rb --grab=0780 --debug --store

**Run commands Docker**: hamster grab 780 --download
                       : hamster grab 780 --store

_June_ 2023_
