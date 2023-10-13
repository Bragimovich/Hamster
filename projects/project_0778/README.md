**Owner**: Ray Piao
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/778

**Dataset**:

    - db01.state_salaries__raw.al_cc_employee_salaries
    - db01.state_salaries__raw.al_cc_salary_schedules
    - db01.state_salaries__raw.al_cc_employee_salaries_runs

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0778 --debug [ --schedules ] [ --buffer=max_buffer_size ]
- Docker
  - hamster grab 778 [ --schedules ] [ --buffer=max_buffer_size ]

_May 2023_
