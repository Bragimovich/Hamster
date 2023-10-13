CREATE TABLE IF NOT EXISTS `crime_inmate`.`nm_bernalillo_inmates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(255) DEFAULT NULL,
  `first_name` VARCHAR(255) DEFAULT NULL,
  `middle_name` VARCHAR(255) DEFAULT NULL,
  `last_name` VARCHAR(255) DEFAULT NULL,
  `suffix` VARCHAR(255) DEFAULT NULL,
  `birthdate` DATE DEFAULT NULL,
  `date_of_death` DATE DEFAULT NULL,
  `age`  VARCHAR(255) DEFAULT NULL,
  `sex` VARCHAR(5) DEFAULT NULL,
  `race` VARCHAR(255) DEFAULT NULL,
  `data_source_url` TEXT DEFAULT NULL,
  `created_by` VARCHAR(255) DEFAULT 'Usman',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) DEFAULT NULL,
  `touched_run_id` BIGINT(20) DEFAULT NULL,
  `deleted` TINYINT(1) DEFAULT '0',
  `md5_hash` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
)
ENGINE = InnoDB
AUTO_INCREMENT = 2377
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Usman, Task #815';
