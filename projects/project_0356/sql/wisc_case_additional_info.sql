CREATE TABLE `wisc_case_additional_info`
(
  `id`                            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`                      INTEGER            DEFAULT NULL,
  `case_id`                       VARCHAR(150)       DEFAULT NULL,

  `lower_court_name`              VARCHAR(255)       DEFAULT NULL,
  `lower_case_id`                 VARCHAR(150)       DEFAULT NULL,
  `lower_judge_name`              VARCHAR(255)       DEFAULT NULL,
  `lower_link`                    VARCHAR(255)       DEFAULT NULL,
  `disposition`                   VARCHAR(255)       DEFAULT NULL,
  `md5_hash`                      VARCHAR(32)        DEFAULT NULL,

  `created_by`                    VARCHAR(255)       DEFAULT 'Eldar Eminov',
  `created_at`                    DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
