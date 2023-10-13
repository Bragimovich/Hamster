CREATE TABLE IF NOT EXISTS `crime_inmate`.`maryland_holding_facilities` 
(
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
  `data_source_url` varchar(255) NULL DEFAULT "https://www.dpscs.state.md.us/inmate/",
  `created_by` VARCHAR(255) NULL DEFAULT 'Habib',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash`) ,
  INDEX `run_id` (`run_id` ) ,
  INDEX `touched_run_id` (`touched_run_id`) ,
  INDEX `deleted` (`deleted`),
  INDEX `fk_holding_facilities_holding_facilities_addresses1_idx` (`holding_facilities_addresse_id`),
   CONSTRAINT `fk_holding_facilities_holding_facilities_addresses_1`
    FOREIGN KEY (`holding_facilities_addresse_id`)
    REFERENCES `crime_inmate`.`maryland_holding_facilities_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
