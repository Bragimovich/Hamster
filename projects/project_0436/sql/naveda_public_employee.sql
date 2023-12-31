create table `nv_public_employee_salary`
(
  `id`                    bigint(20) auto_increment   primary key,
  `year`                  VARCHAR(255),
  `full_name`                  VARCHAR(255),
  `first_name`                  VARCHAR(255),
  `middle_name`                  VARCHAR(255),
  `last_name`                  VARCHAR(255),
  `name_clean`         VARCHAR(255),
  `job_title`           VARCHAR(255),
  `job_title_clean`           VARCHAR(255),
  `agency`           VARCHAR(255),
  `regular_pay`           decimal(65,2),
  `overtime_pay`           decimal(65,2),
  `other_pay`           decimal(65,2),
  `total_pay`           decimal(65,2),
  `total_benefits`            decimal(65,2),
  `total_pay_and_benefits`           decimal(65,2),
  `link`                   VARCHAR(255),
  `last_scrape_date`      Date,
  `next_scrape_date`      Date,
  `md5_hash`                  varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', year, full_name, first_name, middle_name, last_name, job_title, agency,CAST(regular_pay as CHAR),CAST(overtime_pay as CHAR),CAST(other_pay as CHAR),CAST(total_pay_and_benefits as CHAR),CAST(total_pay as CHAR),CAST(total_benefits as CHAR),link))) STORED,
  `run_id`                 int,
  `data_source_url`           VARCHAR(255)  DEFAULT 'https://transparentnevada.com/salaries/',
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `scrape_dev_name`           VARCHAR(255)       DEFAULT 'Aqeel',
  `scrape_frequency`     varchar(255)       DEFAULT 'Yearly',
  `expected_scrape_frequency` varchar(255)  DEFAULT 'Yearly',
  `dataset_name_prefix`      varchar(255)       DEFAULT "naveda_public_employee_salary",
  `scrape_status`        varchar(255)       DEFAULT "Live",
  `pl_gather_task_ID`     bigint(20)        DEFAULT "167979881",
  `created_at`           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
