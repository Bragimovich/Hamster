CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_inmates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(255) NULL DEFAULT NULL,
  `first_name` VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` VARCHAR(255) NULL DEFAULT NULL,
  `last_name` VARCHAR(255) NULL DEFAULT NULL,
  `suffix` VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` DATE NULL DEFAULT NULL,
  `sex` VARCHAR(10) NULL DEFAULT NULL,
  `race` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `deleted` (`deleted` ASC)
) ENGINE = InnoDB AUTO_INCREMENT = 2377 DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_inmate_ids` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `type` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `ms_il_tazewell__arrestee_ids_il_tazewell__arrestees1_idx` (`inmate_id` ASC),
  CONSTRAINT `ms_il_tazewell__arrestee_ids_il_tazewell__arrestees1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`mississippi_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB AUTO_INCREMENT = 2375 DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_inmate_additional_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `height` VARCHAR(255) NULL DEFAULT NULL,
  `weight` VARCHAR(255) NULL DEFAULT NULL,
  `hair_color` VARCHAR(255) NULL DEFAULT NULL,
  `eye_color` VARCHAR(255) NULL DEFAULT NULL,
  `complexion` VARCHAR(255) NULL DEFAULT NULL,
  `build` VARCHAR(255) NULL DEFAULT NULL,
  `risk_level` VARCHAR(255) NULL DEFAULT NULL,
  `visitation_status` VARCHAR(255) NULL DEFAULT NULL,
  `current_location` VARCHAR(255) NULL DEFAULT NULL,
  `unit` VARCHAR(255) NULL DEFAULT NULL,
  `number_of_sentence` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  INDEX `ms_inmate_additional_info_inmates1_idx` (`inmate_id` ASC),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC),
  CONSTRAINT `ms_inmate_additional_info_inmates1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`mississippi_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_physical_location_histories` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `location` VARCHAR(255) NULL DEFAULT NULL,
  `movement_date` DATE NULL DEFAULT NULL,
  `reason` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `ms_physical_location_history_inmates1_idx` (`inmate_id` ASC),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC),
  CONSTRAINT `ms_physical_location_history_inmates1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`mississippi_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_mugshots` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `aws_link` VARCHAR(255) NULL DEFAULT NULL,
  `original_link` VARCHAR(255) NULL DEFAULT NULL,
  `notes` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `ms_il_tazewell__mugshots_il_tazewell__arrestees1_idx` (`inmate_id` ASC),
  CONSTRAINT `ms_il_tazewell__mugshots_il_tazewell__arrestees1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`mississippi_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_arrests` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `officer` VARCHAR(255) NULL DEFAULT NULL,
  `arrest_date` DATETIME NULL DEFAULT NULL,
  `booking_date` DATETIME NULL DEFAULT NULL,
  `booking_agency` VARCHAR(255) NULL DEFAULT NULL,
  `booking_number` VARCHAR(255) NULL DEFAULT NULL,
  `actual_booking_number` VARCHAR(255) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `ms_il_tazewell__arrests_il_tazewell__arrestees_idx` (`inmate_id` ASC),
  CONSTRAINT `ms_il_tazewell__arrests_il_tazewell__arrestees`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`mississippi_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_charges` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `disposition` VARCHAR(255) NULL DEFAULT NULL,
  `disposition_date` DATE NULL DEFAULT NULL,
  `description` VARCHAR(255) NULL DEFAULT NULL,
  `offense_type` VARCHAR(255) NULL DEFAULT NULL,
  `offense_date` DATE NULL DEFAULT NULL,
  `docket_number` VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` VARCHAR(255) NULL DEFAULT NULL,
  `counts` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `ms_il_tazewell__charges_il_tazewell__arrests1_idx` (`arrest_id` ASC),
  CONSTRAINT `ms_il_tazewell__charges_il_tazewell__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`mississippi_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_court_addresses` (
  `court_id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_address` VARCHAR(255) NULL DEFAULT NULL,
  `city` VARCHAR(255) NULL DEFAULT NULL,
  `county` VARCHAR(255) NULL DEFAULT NULL,
  `state` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`court_id`),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_court_hearings` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `court_address_id` BIGINT(20) NULL,
  `court_name` VARCHAR(255) NULL DEFAULT NULL,
  `court_date` DATE NULL DEFAULT NULL,
  `court_time` TIME NULL DEFAULT NULL,
  `next_court_date` DATE NULL,
  `next_court_time` TIME NULL,
  `court_room` VARCHAR(255) NULL DEFAULT NULL,
  `case_number` VARCHAR(255) NULL DEFAULT NULL,
  `case_type` VARCHAR(255) NULL DEFAULT NULL,
  `sentence_lenght` VARCHAR(255) NULL,
  `sentence_type` VARCHAR(255) NULL,
  `min_release_date` DATE NULL,
  `max_release_date` DATE NULL,
  `set_by` BIGINT(20) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `ms_il_tazewell__court_hearings_il_tazewell__charges1_idx` (`charge_id` ASC),
  INDEX `ms_court_hearings_court_addresses1_idx` (`court_address_id` ASC),
  CONSTRAINT `ms_il_tazewell__court_hearings_il_tazewell__charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`mississippi_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `ms_court_hearings_court_addresses1`
    FOREIGN KEY (`court_address_id`)
    REFERENCES `crime_inmate`.`mississippi_court_addresses` (`court_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`mississippi_holding_facilities` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `facility` VARCHAR(255) NULL DEFAULT NULL,
  `facility_type` VARCHAR(255) NULL DEFAULT NULL,
  `start_date` DATE NULL DEFAULT NULL,
  `planned_release_date` DATE NULL DEFAULT NULL,
  `actual_release_date` DATE NULL DEFAULT NULL,
  `max_release_date` VARCHAR(255) NULL,
  `total_time` VARCHAR(255) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
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
  INDEX `ms_il_tazewell__holding_facilities_il_tazewell__arrests1_idx` (`arrest_id` ASC),
  CONSTRAINT `ms_il_tazewell__holding_facilities_il_tazewell__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`mississippi_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;
