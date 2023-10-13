CREATE TABLE `final_result_scores_players` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `game_id` BIGINT NULL,
  `person_id` BIGINT NULL,
  `school_id` BIGINT NULL,
  `pos` VARCHAR(45) NULL,
  `AB` INT NULL,
  `R`  INT NULL,
  `H`  INT NULL,
  `BI` INT NULL,
  `2B` INT NULL,
  `3B` INT NULL,
  `HR` INT NULL,
  `BB` INT NULL,
  `SB` INT NULL,
  `CS` INT NULL,
  `HP` INT NULL,
  `SH` INT NULL,
  `SF` INT NULL,
  `IBB`INT NULL,
  `KL` INT NULL,
  `GDP`INT NULL,
  `RBI`INT NULL,
  `SO` INT NULL,
  `PO` INT NULL,
  `A`  INT NULL,
  `E`  INT NULL,
  `LOB`INT NULL,
  `ex_player_name` VARCHAR(255) NULL,
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
  `md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', game_id, person_id, school_id, pos, AB, R, H, BI, 2B, 3B, HR, BB, SB, CS, HP, SH, SF, IBB, KL, GDP, RBI, SO, PO, A, E, LOB, data_source_url))) STORED,
  `ex_md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', ex_player_name, ex_school_name, pos, AB, R, H, BI, 2B, 3B, HR, BB, SB, CS, HP, SH, SF, IBB, KL, GDP, RBI, SO, PO, A, E, LOB, data_source_url))) STORED,
  UNIQUE KEY `md5` (`ex_md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  PRIMARY KEY (`id`)
  )DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  