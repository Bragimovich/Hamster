CREATE TABLE `oh_higher_ed_salaries`
(
  `id`                              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                          BIGINT(20),

  `as_of_date`                      VARCHAR(255),
  `preferred_last_name`             VARCHAR(255),
  `preferred_first_name`            VARCHAR(255),
  `cost_center_hierarchy_cch6`      VARCHAR(255),
  `cost_center`                     VARCHAR(255),
  `job_profile`                     VARCHAR(255),
  `fte`                             VARCHAR(255),
  `pay_rate_type`                   VARCHAR(255),
  `base_pay_psn`                    VARCHAR(255),
  `position_group`                  VARCHAR(255),
  `identifier`                      VARCHAR(255),

  `data_source_url`                 TEXT,
  `created_by`                      VARCHAR(255)      DEFAULT 'Shahrukh',
  `created_at`                      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`                  BIGINT,
  `deleted`                         BOOLEAN           DEFAULT 0,
  `md5_hash`                        VARCHAR(255),

  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Shahrukh';
