CREATE TABLE `us_case_party`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`      VARCHAR(255),
  `case_id`      VARCHAR(255),
  `party_name`      VARCHAR(255),
  `party_type`      VARCHAR(255),
  `party_address`      VARCHAR(255),
  `party_city`      VARCHAR(255),
  `party_state`      VARCHAR(255),
  `party_zip`      VARCHAR(255),


  `scrape_dev_name`      VARCHAR(255)       DEFAULT 'Magusch',
  `data_source_url` TEXT,
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequncy` VARCHAR(255)       DEFAULT 'daily',

  `last_scrape_date`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `next_scrape_date`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `expected_scrape_frequncy` VARCHAR(255)       DEFAULT 'daily',
  `pl_gather_task_id` INT(11)

) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
