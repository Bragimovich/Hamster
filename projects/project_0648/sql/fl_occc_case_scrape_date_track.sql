CREATE TABLE `fl_occc_case_scrape_date_track`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `year`            int not null,
  `month`           int not null DEFAULT 0,
  `day`             int not null DEFAULT 0,
  `letter`          VARCHAR(5) not null DEFAULT '-',
  `case_type`       VARCHAR(255) not null,
  `is_completed`    BOOLEAN   DEFAULT 0,
  `no_links`        BOOLEAN   DEFAULT 0,
  `bad_request`     BOOLEAN   DEFAULT 0,
  `need_to_split`   BOOLEAN   DEFAULT 0,
  `processing_error`   BOOLEAN   DEFAULT 0,
  `created_by`      VARCHAR(255)       DEFAULT 'Muhammad Qasim',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_date` (`year`,`month`,`day`, `case_type`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

