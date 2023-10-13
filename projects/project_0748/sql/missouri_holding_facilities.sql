CREATE TABLE `missouri_holding_facilities` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `holding_facilities_addresse_id` BIGINT(20) NULL,
  `facility` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Usman',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash`) ,
  INDEX `run_id` (`run_id`) ,
  INDEX `touched_run_id` (`touched_run_id`) ,
  INDEX `deleted` (`deleted`) ,
  INDEX `fk_holding_facilities_holding_facilities_addresses1_idx` (`holding_facilities_addresse_id`) ,
  INDEX `fk_il_tazewell__holding_facilities_il_tazewell__arrests1_idx` (`arrest_id`) ,
  CONSTRAINT `fk_il_tazewell__holding_facilities_il_tazewell__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`missouri_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_holding_facilities_holding_facilities_addresses1`
    FOREIGN KEY (`holding_facilities_addresse_id`)
    REFERENCES `crime_inmate`.`missouri_holding_facilities_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Muhammad Usman, Task #0748';
