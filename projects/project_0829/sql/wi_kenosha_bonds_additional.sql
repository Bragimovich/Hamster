CREATE TABLE IF NOT EXISTS `crime_inmate`.`wi_kenosha_bonds_additional` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `bond_id` BIGINT(20) NULL DEFAULT NULL,
  `key` VARCHAR(255) NULL DEFAULT NULL,
  `value` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Zaid Akram',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC) ,
  INDEX `fk_bonds_additional_bonds2_idx` (`bond_id` ASC) ,
  CONSTRAINT `fk_bonds_additional_bonds2`
    FOREIGN KEY (`bond_id`)
    REFERENCES `crime_inmate`.`wi_kenosha_bonds` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
