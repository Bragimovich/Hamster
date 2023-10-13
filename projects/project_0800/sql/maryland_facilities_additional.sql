CREATE TABLE IF NOT EXISTS `crime_inmate`.`maryland_holding_facilities_additional` 
(
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `holding_facilities_id` BIGINT(20) NOT NULL,
  `key` VARCHAR(255) NULL DEFAULT NULL,
  `value` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Habib',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_holding_facilities_additional_holding_facilities1_idx` (`holding_facilities_id` ASC) ,
  CONSTRAINT `fk_holding_facilities_additional_holding_facilities10`
    FOREIGN KEY (`holding_facilities_id`)
    REFERENCES `crime_inmate`.`maryland_holding_facilities_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
