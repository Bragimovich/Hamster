CREATE TABLE IF NOT EXISTS `ga_gwinnett_immates` (
  `id`              BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name`       VARCHAR(255) NULL DEFAULT NULL,
  `first_name`      VARCHAR(255) NULL DEFAULT NULL,
  `middle_name`     VARCHAR(255) NULL DEFAULT NULL,
  `last_name`       VARCHAR(255) NULL DEFAULT NULL,
  `suffix`          VARCHAR(255) NULL DEFAULT NULL,
  `birthdate`       DATE NULL DEFAULT NULL,
  `date_of_death`   DATE NULL DEFAULT NULL,
  `sex`             VARCHAR(10) NULL DEFAULT NULL,
  `race`            VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by`      VARCHAR(255) NULL DEFAULT 'Asim Saeed',
  `created_at`      DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`  BIGINT(20) NULL DEFAULT NULL,
  `deleted`         TINYINT(1) NULL DEFAULT '0',
  `md5_hash`        VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  )
ENGINE = InnoDB
AUTO_INCREMENT = 2377
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Asim Saeed, Task #0735';