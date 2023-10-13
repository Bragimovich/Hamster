CREATE TABLE `fl_occc_case_scrape_date_track_cron`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `searched_date`   date null,
  `case_type`       VARCHAR(255) not null DEFAULT '',
  `letter`          VARCHAR(5) not null DEFAULT '-',
  `is_completed`    BOOLEAN   DEFAULT 0,
  `no_links`        BOOLEAN   DEFAULT 0,
  `bad_request`    BOOLEAN   DEFAULT 0,
  `processing_error`    BOOLEAN   DEFAULT 0,
  `case_type_completed`        BOOLEAN   DEFAULT 0,
  `letter_completed`     BOOLEAN   DEFAULT 0,
  `created_by`      VARCHAR(255)       DEFAULT 'Muhammad Qasim',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_date` (`searched_date`,`case_type`,`letter`, `is_completed`,`no_links`, `bad_request`, `processing_error`, `case_type_completed`, `letter_completed`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
