CREATE TABLE `final_result_additions_desc` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `descriptions` VARCHAR(1024) NULL,
  `game_id` BIGINT NULL,
  `ex_vs_school_name_1` VARCHAR(255) NULL,
  `ex_vs_school_name_2` VARCHAR(255) NULL,
  `ex_school_score_1` VARCHAR(255) NULL,
  `ex_school_score_2` VARCHAR(255) NULL,
  `ex_date_and_loc` VARCHAR(255) NULL,
  `ex_raw_data` VARCHAR(255) NULL,
  `touched_run_id` INT NULL,
  `data_source_url` VARCHAR(255) NOT NULL,
  `created_by` VARCHAR(255) DEFAULT "Muhammad Qasim",
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', descriptions, game_id, data_source_url ))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  PRIMARY KEY (`id`)
  ) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  