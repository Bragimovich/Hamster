CREATE TABLE IF NOT EXISTS `crime_inmate`.`mo_jackson_inmate_ids_additional` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_ids_id` BIGINT(20) NOT NULL,
  `key` VARCHAR(255) NULL DEFAULT NULL,
  `value` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Asim',
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
  INDEX `fk_mo_jackson_inmate_ids_additional_mo_jackson_inmate_ids1_idx` (`inmate_ids_id` ASC),
  CONSTRAINT `fk_mo_jackson_inmate_ids_additional_mo_jackson_inmate_ids1`
    FOREIGN KEY (`inmate_ids_id`)
    REFERENCES `crime_inmate`.`mo_jackson_inmate_ids` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Asim Saeed, Task #807';
