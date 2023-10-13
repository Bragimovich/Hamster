**Owner**: Umar Farooq

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/742

**Dataset**: db01.raw_contributions.VA_RAW_CandidateCampaignCommittee
             db01.raw_contributions.VA_RAW_FederalPoliticalActionCommittee
             db01.raw_contributions.VA_RAW_InauguralCommittee
             db01.raw_contributions.VA_RAW_OutOfStatePoliticalActionCommittee
             db01.raw_contributions.VA_RAW_PoliticalPartyCommittee
             db01.raw_contributions.VA_RAW_PoliticalActionCommittee
             db01.raw_contributions.VA_RAW_REPORT
             db01.raw_contributions.VA_RAW_RUNS
             db01.raw_contributions.VA_RAW_ReferendumCommittee
             db01.raw_contributions.VA_RAW_SCHEDULEA
             db01.raw_contributions.VA_RAW_SCHEDULEB
             db01.raw_contributions.VA_RAW_SCHEDULEC
             db01.raw_contributions.VA_RAW_SCHEDULED
             db01.raw_contributions.VA_RAW_SCHEDULEE
             db01.raw_contributions.VA_RAW_SCHEDULEF
             db01.raw_contributions.VA_RAW_SCHEDULEG
             db01.raw_contributions.VA_RAW_SCHEDULEH
             db01.raw_contributions.VA_RAW_SCHEDULEI

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0742 --debug --download
                     : bundle exec ruby hamster.rb --grab=0742 --debug --store

**Run commands Docker**: hamster grab 742 --download
                       : hamster grab 742 --store

_April_ 2023_
