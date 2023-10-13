**Owner**: Hassan Nawaz

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/731

**Dataset**: db01.raw_contributions.la_campaign_candidates
             db01.raw_contributions.la_campaign_committees
             db01.raw_contributions.la_campaign_contributions
             db01.raw_contributions.la_campaign_expenditures
             db01.raw_contributions.la_campaign_political_action_committees
             db01.raw_contributions.la_campaign_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0731 --debug --download first
                     : bundle exec ruby hamster.rb --grab=0731 --debug --download second

**Run commands Docker**: hamster grab 731 --download first
                       : hamster grab 731 --download second

_May_ 2023_
