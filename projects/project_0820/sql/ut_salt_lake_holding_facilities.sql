CREATE TABLE IF NOT EXISTS `crime_inmate`.`ut_salt_lake_holding_facilities` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `holding_facilities_addresse_id` BIGINT(20) NULL,
  `facility` VARCHAR(255) NULL DEFAULT NULL,
  `facility_type` VARCHAR(255) NULL DEFAULT NULL,
  `facility_subtype` VARCHAR(255) NULL DEFAULT NULL,
  `start_date` DATE NULL DEFAULT NULL,
  `planned_release_date` DATE NULL DEFAULT NULL,
  `actual_release_date` DATE NULL DEFAULT NULL,
  `max_release_date` VARCHAR(255) NULL,
  `total_time` VARCHAR(255) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Muhammad Musa',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_il_tazewell__holding_facilities_il_tazewell__arrests1_idx` (`arrest_id` ASC),
  INDEX `fk_holding_facilities_holding_facilities_addresses1_idx` (`holding_facilities_addresse_id` ASC),
  CONSTRAINT `fk_il_tazewell__holding_facilities_il_tazewell__arrests820`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`ut_salt_lake_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_holding_facilities_holding_facilities_addresses820`
    FOREIGN KEY (`holding_facilities_addresse_id`)
    REFERENCES `crime_inmate`.`ut_salt_lake_holding_facilities_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Muhammad Musa, Task #820';
