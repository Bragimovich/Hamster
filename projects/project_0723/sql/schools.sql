CREATE TABLE `schools`(
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NULL,
  `contact_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `aliase_name` VARCHAR(255) NULL,
  `enrollment` VARCHAR(255) NULL DEFAULT NULL,
  `nicknames` VARCHAR(255) NULL DEFAULT NULL,
  `colors` VARCHAR(255) NULL DEFAULT NULL,
  `school_type` VARCHAR(255) NULL,
  `conferences` VARCHAR(255) NULL DEFAULT NULL,
  `county` VARCHAR(255) NULL,
  `cities_in_district` VARCHAR(255) NULL,
  `broad_division` INT NULL,
  `legislative_district` INT NULL,
  `touched_run_id` INT NULL,
  `data_source_url` VARCHAR(255) NOT NULL,
  `created_by` VARCHAR(255) DEFAULT "Muhammad Qasim",
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `md5_hash` VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', contact_id, name, aliase_name, enrollment, nicknames, colors,  school_type, conferences, county, cities_in_district, broad_division, legislative_district, data_source_url))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;