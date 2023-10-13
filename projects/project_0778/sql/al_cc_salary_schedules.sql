CREATE TABLE `al_cc_salary_schedules`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `academic_year`   VARCHAR(255),
  `institution`     VARCHAR(255),
  `salary_schedule` VARCHAR(255),
  `job_type`        VARCHAR(255),
  `salary_rank`     VARCHAR(255),
  `grade`           VARCHAR(255),
  `position_title`  VARCHAR(255),
  `salary_period`   VARCHAR(255),
  `salary_step`     VARCHAR(255),
  `value`           VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Ray Piao',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Ray Piao';
