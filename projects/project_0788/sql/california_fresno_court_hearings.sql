CREATE TABLE IF NOT EXISTS `california_fresno_court_hearings` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `court_address_id` BIGINT(20) DEFAULT NULL,
  `court_name` VARCHAR(255) NULL DEFAULT NULL,
  `court_date` DATE NULL DEFAULT NULL,
  `court_time` TIME NULL DEFAULT NULL,
  `next_court_date` DATE NULL,
  `next_court_time` TIME NULL,
  `court_room` VARCHAR(255) NULL DEFAULT NULL,
  `case_number` VARCHAR(255) NULL DEFAULT NULL,
  `case_type` VARCHAR(255) NULL DEFAULT NULL,
  `sentence_lenght` VARCHAR(255) NULL,
  `sentence_type` VARCHAR(255) NULL,
  `min_release_date` DATE NULL,
  `max_release_date` DATE NULL,
  `set_by` BIGINT(20) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Usman',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_il_tazewell__court_hearings_il_tazewell__charges1_idx` (`charge_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__court_hearings_il_tazewell__charges15`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`california_fresno_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Muhammad Usman, Task #0788';
