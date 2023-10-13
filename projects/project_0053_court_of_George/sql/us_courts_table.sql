CREATE TABLE `us_courts_table`
(
  `court_id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_name`      VARCHAR(255),
  `court_state`      VARCHAR(255),
  `court_type`      VARCHAR(255),
  `court_sub_type`      VARCHAR(255),

  `scrape_dev_name`      VARCHAR(255)       DEFAULT 'Magusch',
  `data_source_url` TEXT,

  `created_at`      TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `scrape_frequency`      VARCHAR(255),
  `last_scrape_date`      DATE,
  `next_scrape_date`      DATE,
  `expected_scrape_frequency`      VARCHAR(255),
  `pl_gather_task_id`    INT(11)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
