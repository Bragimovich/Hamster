CREATE TABLE `me_enrollment`
(
  `id`              	BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          	BIGINT(20),
  `general_id`            BIGINT(20),
  `school_year`            varchar(50)   null,
  `subgroup`        varchar(255)   null,
  `demographic`         varchar(255)   null,
  `subgroup_count`      varchar(255)   null,
  `students_count`      varchar(255)   null,
  `students_percent`    varchar(255)   null,
  `data_source_url` varchar(255),
  `created_by`      varchar(255)      DEFAULT 'Habib',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        varchar(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  KEY `id` (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

