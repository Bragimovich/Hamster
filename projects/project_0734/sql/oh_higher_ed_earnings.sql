CREATE TABLE `oh_higher_ed_earnings`
(
  `id`                              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                          BIGINT(20),

  `last_legal_name`                 VARCHAR(255),
  `first_name_preferred`            VARCHAR(255),
  `job_profile_name`                VARCHAR(255),
  `cost_center`                     VARCHAR(255),
  `cost_center_hierarchy_cch6`      VARCHAR(255),
  `position_group`                  VARCHAR(255),
  `regular_pay`                     VARCHAR(255),
  `bonus`                           VARCHAR(255),
  `overtime`                        VARCHAR(255),
  `other`                           VARCHAR(255),
  `gross_pay`                       VARCHAR(255),

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
