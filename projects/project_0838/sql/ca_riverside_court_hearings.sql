CREATE TABLE IF NOT EXISTS `crime_inmate`.`ca_riverside_court_hearings` (
  `id`               BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id`        BIGINT(20) NULL DEFAULT NULL,
  `court_name`       VARCHAR(255) NULL DEFAULT NULL,
  `next_court_date`  DATE NULL DEFAULT NULL,
  `next_court_time`  TIME NULL DEFAULT NULL,
  `data_source_url`  TEXT NULL DEFAULT NULL,
  `created_by`       VARCHAR(255) NULL DEFAULT 'Abdul Wahab',
  `created_at`       DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`           BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`   BIGINT(20) NULL DEFAULT NULL,
  `deleted`          TINYINT(1) NULL DEFAULT '0',
  `md5_hash`         VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_riverside_tazewell__court_hearings_il_tazewell__charges1_idx` (`charge_id` ASC) ,
  CONSTRAINT `fk_riverside_tazewell__court_hearings_il_tazewell__charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`ca_riverside_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;