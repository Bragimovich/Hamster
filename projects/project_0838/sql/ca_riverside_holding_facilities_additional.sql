CREATE TABLE IF NOT EXISTS `crime_inmate`.`ca_riverside_holding_facilities_additional` (
  `id`                  BIGINT(20) NOT NULL AUTO_INCREMENT,
  `holding_facility_id` BIGINT(20) NULL DEFAULT NULL,
  `key`                 VARCHAR(255) NULL DEFAULT NULL,
  `value`               VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url`     TEXT NULL DEFAULT NULL,
  `created_by`          VARCHAR(255) NULL DEFAULT 'Abdul Wahab',
  `created_at`          DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`              BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`      BIGINT(20) NULL DEFAULT NULL,
  `deleted`             TINYINT(1) NULL DEFAULT '0',
  `md5_hash`            VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC) ,
  INDEX `fk_rs_holding_facilities_additional_holding_facilities2_idx` (`holding_facility_id` ASC) ,
  CONSTRAINT `fk_riverside_holding_facilities_additional_holding_facilities2`
    FOREIGN KEY (`holding_facility_id`)
    REFERENCES `crime_inmate`.`ca_riverside_holding_facilities` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;