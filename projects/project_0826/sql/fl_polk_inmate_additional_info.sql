CREATE TABLE IF NOT EXISTS `crime_inmate`.`fl_polk_inmate_additional_info` (
  `id` BIGINT(20) NOT NULL AUTO INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `height` VARCHAR(255) NULL DEFAULT NULL,
  `weight` VARCHAR(255) NULL DEFAULT NULL,
  `hair_color` VARCHAR(255) NULL DEFAULT NULL,
  `eye_color` VARCHAR(255) NULL DEFAULT NULL,
  `age` INT(11) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Hatri',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  INDEX `fk_polk_inmate_additional_info_idx` (`inmate_id` ASC) VISIBLE,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_fl_polk_immate_additional_info`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`fl_polk_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Hatri, Task #826';

SHOW WARNINGS;
