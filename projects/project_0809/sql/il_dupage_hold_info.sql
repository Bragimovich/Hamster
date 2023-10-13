CREATE TABLE IF NOT EXISTS `il_dupage_hold_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `agency_name` VARCHAR(255) NULL DEFAULT NULL,
  `bond_amount` VARCHAR(255) NULL DEFAULT NULL,
  `bond_fees` VARCHAR(45) NULL DEFAULT NULL,
  `paid_status` VARCHAR(1020) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Azeem Arif',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR (255) GENERATED ALWAYS AS (md5(concat_ws('',agency_name,bond_amount,bond_fees,paid_status,arrest_id))) STORED,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  FOREIGN KEY (`arrest_id`)
  REFERENCES `crime_inmate`.`il_dupage_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Azeem Arif, Task #809';
