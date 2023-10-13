CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_inmates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(255) NULL DEFAULT NULL,
  `first_name` VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` VARCHAR(255) NULL DEFAULT NULL,
  `last_name` VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` DATE NULL DEFAULT NULL,
  `sex` VARCHAR(6) NULL DEFAULT NULL,
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
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_inmate_ids` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `type` VARCHAR(255) NULL DEFAULT NULL,
  `date_from` DATE NULL DEFAULT NULL,
  `date_to` DATE NULL DEFAULT NULL,
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
  INDEX `wa_sh_tazewell__wa_snohomish_inmate_ids_idx` (`inmate_id` ASC),
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_inmate_ids`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_arrests` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `officer` VARCHAR(255) NULL DEFAULT NULL,
  `arrest_date` DATETIME NULL DEFAULT NULL,
  `booking_date` DATETIME NULL DEFAULT NULL,
  `booking_agency` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_type` VARCHAR(255) NULL DEFAULT NULL,
  `booking_number` VARCHAR(255) NULL DEFAULT NULL,
  `actual_booking_number` VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `wa_sh_tazewell__wa_snohomish_arrests_idx` (`inmate_id` ASC),
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_arrests`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_charges` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `disposition` VARCHAR(255) NULL DEFAULT NULL,
  `disposition_date` DATE NULL DEFAULT NULL,
  `description` VARCHAR(255) NULL DEFAULT NULL,
  `offense_type` VARCHAR(255) NULL DEFAULT NULL,
  `offense_date` DATE NULL DEFAULT NULL,
  `offense_time` TIME NULL DEFAULT NULL,
  `attempt_or_commit` VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `wa_sh_tazewell__wa_snohomish_charges_idx` (`arrest_id` ASC),
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_charges`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_bonds` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `bond_category` VARCHAR(255) NULL DEFAULT NULL,
  `bond_number` VARCHAR(255) NULL DEFAULT NULL,
  `bond_type` VARCHAR(255) NULL DEFAULT NULL,
  `bond_amount` VARCHAR(255) NULL DEFAULT NULL,
  `paid` INT(11) NULL DEFAULT NULL,
  `bond_fees` VARCHAR(45) NULL DEFAULT NULL,
  `paid_status` VARCHAR(1020) NULL DEFAULT NULL,
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
  INDEX `wa_sh_tazewell__wa_snohomish_bonds1_idx` (`arrest_id` ASC),
  INDEX `wa_sh_tazewell__wa_snohomish_bonds2_idx` (`charge_id` ASC),
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_bonds1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_bonds2`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_court_hearings` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `court_name` VARCHAR(255) NULL DEFAULT NULL,
  `court_date` DATE NULL DEFAULT NULL,
  `court_time` TIME NULL DEFAULT NULL,
  `next_court_date` DATE NULL DEFAULT NULL,
  `next_court_time` TIME NULL DEFAULT NULL,
  `court_room` VARCHAR(255) NULL DEFAULT NULL,
  `case_number` VARCHAR(255) NULL DEFAULT NULL,
  `case_type` VARCHAR(255) NULL DEFAULT NULL,
  `sentence_length` VARCHAR(255) NULL DEFAULT NULL,
  `sentence_type` VARCHAR(255) NULL DEFAULT NULL,
  `min_release_date` DATE NULL DEFAULT NULL,
  `max_release_date` DATE NULL DEFAULT NULL,
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
  INDEX `wa_sh_tazewell__wa_snohomish_court_hearings_idx` (`charge_id` ASC),
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_court_hearings`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_holding_facilities` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `facility` VARCHAR(255) NULL DEFAULT NULL,
  `facility_type` VARCHAR(255) NULL DEFAULT NULL,
  `start_date` DATE NULL DEFAULT NULL,
  `planned_release_date` DATE NULL DEFAULT NULL,
  `actual_release_date` DATE NULL DEFAULT NULL,
  `max_release_date` VARCHAR(255) NULL DEFAULT NULL,
  `total_time` VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `wa_sh_tazewell__wa_snohomish_holding_facilities_idx` (`arrest_id` ASC),
  CONSTRAINT `wa_sh_tazewell__wa_snohomish_holding_facilities`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_inmate_additional_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `height` VARCHAR(255) NULL DEFAULT NULL,
  `weight` VARCHAR(255) NULL DEFAULT NULL,
  `hair_color` VARCHAR(255) NULL DEFAULT NULL,
  `eye_color` VARCHAR(255) NULL DEFAULT NULL,
  `street_address` VARCHAR(255) NULL DEFAULT NULL,
  `age` INT(11) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `current_location` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `wa_sh_tazewell__snohomish_inmate_additional_info_idx` (`inmate_id` ASC),
  CONSTRAINT `wa_sh_tazewell__snohomish_inmate_additional_info`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_inmate_statuses` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `date_of_status_change` DATE NULL DEFAULT NULL,
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
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `wa_sh_tazewell__snohomish_inmate_statuses_idx` (`inmate_id` ASC),
  CONSTRAINT `wa_sh_tazewell__snohomish_inmate_statuses`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `crime_inmate`.`wa_snohomish_charges_additional` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `key` VARCHAR(255) NULL DEFAULT NULL,
  `value` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Aleksa Gegic',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `wa_sh_tazewell__snohomish_charges_additional_idx` (`charge_id` ASC),
  PRIMARY KEY (`id`),
  CONSTRAINT `wa_sh_tazewell__snohomish_charges_additional`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`wa_snohomish_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;
