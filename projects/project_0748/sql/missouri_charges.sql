CREATE TABLE `missouri_charges` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `name` VARCHAR(512) NULL DEFAULT NULL,
  `offense_type` VARCHAR(512) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Usman',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`) ,
  INDEX `touched_run_id` (`touched_run_id`) ,
  INDEX `deleted` (`deleted`) ,
  INDEX `fk_il_tazewell__charges_il_tazewell__arrests_idx` (`arrest_id`) ,
  CONSTRAINT `fk_il_tazewell__charges_il_tazewell__arrests`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`missouri_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Muhammad Usman, Task #0748';
