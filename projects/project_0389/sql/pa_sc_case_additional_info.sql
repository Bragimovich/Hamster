CREATE TABLE `pa_sc_case_additional_info`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`              SMALLINT           DEFAULT NULL,
  `case_id`               VARCHAR(100)       DEFAULT NULL,

  `lower_court_name`      VARCHAR(255)       DEFAULT NULL,
  `lower_case_id`         VARCHAR(255)       DEFAULT NULL,
  `lower_judge_name`      VARCHAR(1000)      DEFAULT NULL,
  `lower_link`            VARCHAR(255)       DEFAULT NULL,
  `disposition`           VARCHAR(255)       DEFAULT NULL,

  `data_source_url`       VARCHAR(255)       DEFAULT NULL,
  `md5_hash`              VARCHAR(32)        DEFAULT NULL,
  `created_by`            VARCHAR(20)        DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
