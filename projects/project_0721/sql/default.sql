CREATE TABLE `az_esa_reports_quarterly`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),

  `year`            INT,
  `quarter`         INT,
  `district_id`     VARCHAR(50),
  `district_name`   VARCHAR(255),
  `students_count`  VARCHAR(255),

  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255) GENERATED ALWAYS AS (md5(concat_ws('-',year,quarter,district_id,district_name,students_count))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';
