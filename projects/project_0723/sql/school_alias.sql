CREATE TABLE `school_alias`(
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `school_id` VARCHAR(255) NOT NULL,
  `aliase_name` VARCHAR(255) NOT NULL,
  `data_source_url` VARCHAR(255) NULL,
  `touched_run_id` BIGINT NULL,
  `created_by` VARCHAR(255) DEFAULT "Muhammad Qasim",
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', school_id, aliase_name))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
