CREATE TABLE IF NOT EXISTS `final_result_score_by_innings` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `game_id` BIGINT NULL,
  `school_id` BIGINT NULL,
  `scheme` VARCHAR(45) NULL,
  `R` VARCHAR(45) NULL,
  `H` VARCHAR(45) NULL,
  `E` VARCHAR(45) NULL,
  `ex_school_name` VARCHAR(255) NULL,
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
  `md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', game_id, school_id, scheme, R, H, E, data_source_url))) STORED,
  `ex_md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', ex_school_name, scheme, R, H, E, data_source_url))) STORED,
  UNIQUE KEY `md5` (`ex_md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  PRIMARY KEY (`id`)
  )DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  