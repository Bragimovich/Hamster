**Owner**: Tauseeq
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/476

**Dataset**: db01.lawyer_status.georgia
             db01.lawyer_status.indiana
             db01.lawyer_status.michigan
             db01.lawyer_status.inbar_runs
             db01.lawyer_status.ne_bar__nebar_reliaguide_com
             db01.lawyer_status.il_bar__isba_reliaguide_com

STATES = ['georgia', 'indiana', 'michigan','nebraska','illinois']

**Run commands**: hamster grab 476 --download "#{state}"
                  hamster grab 476 --store

_January 2022_
