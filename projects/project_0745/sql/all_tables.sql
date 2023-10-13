CREATE TABLE IF NOT EXISTS `new_hampshire_inmates`
(
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `full_name` VARCHAR(255) NULL DEFAULT NULL,
    `first_name` VARCHAR(255) NULL DEFAULT NULL,
    `middle_name` VARCHAR(255) NULL DEFAULT NULL,
    `last_name` VARCHAR(255) NULL DEFAULT NULL,
    `suffix` VARCHAR(255) NULL DEFAULT NULL,
    `age` INT NULL DEFAULT NULL,
    `data_source_url` TEXT NULL DEFAULT NULL,
    `created_by` VARCHAR(255) NULL DEFAULT 'Halid Ibragimov',
    `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id` BIGINT(20) NULL DEFAULT NULL,
    `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
    `deleted` TINYINT(1) NULL DEFAULT '0',
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `md5` (`md5_hash` ASC) ,
    INDEX `run_id` (`run_id` ASC) ,
    INDEX `touched_run_id` (`touched_run_id` ASC) ,
    INDEX `deleted` (`deleted` ASC)
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 2377
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = '';

CREATE TABLE IF NOT EXISTS `new_hampshire_inmate_ids`
(
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `immate_id` BIGINT(20) NULL DEFAULT NULL,
    `number` VARCHAR(255) NULL DEFAULT NULL,
    `data_source_url` TEXT NULL DEFAULT NULL,
    `created_by` VARCHAR(255) NULL DEFAULT 'Halid Ibragimov',
    `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id` BIGINT(20) NULL DEFAULT NULL,
    `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
    `deleted` TINYINT(1) NULL DEFAULT '0',
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `md5` (`md5_hash` ASC) ,
    INDEX `run_id` (`run_id` ASC) ,
    INDEX `touched_run_id` (`touched_run_id` ASC) ,
    INDEX `deleted` (`deleted` ASC) ,
    INDEX `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees1_idx` (`immate_id` ASC) ,
    CONSTRAINT `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees11`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`new_hampshire_inmates` (`id`)
     ON DELETE NO ACTION
     ON UPDATE NO ACTION
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 2375
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = '';

CREATE TABLE IF NOT EXISTS `new_hampshire_arrests`
(
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `immate_id` BIGINT(20) NULL DEFAULT NULL,
    `booking_date` DATE NULL DEFAULT NULL,
    `data_source_url` TEXT NULL DEFAULT NULL,
    `created_by` VARCHAR(255) NULL DEFAULT 'Halid Ibragimov',
    `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id` BIGINT(20) NULL DEFAULT NULL,
    `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
    `deleted` TINYINT(1) NULL DEFAULT '0',
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `md5` (`md5_hash` ASC) ,
    INDEX `run_id` (`run_id` ASC) ,
    INDEX `touched_run_id` (`touched_run_id` ASC) ,
    INDEX `deleted` (`deleted` ASC) ,
    INDEX `fk_il_tazewell__arrests_il_tazewell__arrestees_idx` (`immate_id` ASC) ,
    CONSTRAINT `fk_il_tazewell__arrests_il_tazewell__arrestees0`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`new_hampshire_inmates` (`id`)
     ON DELETE NO ACTION
     ON UPDATE NO ACTION
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 1385
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = '';

CREATE TABLE IF NOT EXISTS `new_hampshire_holding_facilities`
(
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `arrest_id` BIGINT(20) NULL DEFAULT NULL,
    `facility` VARCHAR(255) NULL DEFAULT NULL,
    `max_release_date` VARCHAR(255) NULL,
    `data_source_url` TEXT NULL DEFAULT NULL,
    `created_by` VARCHAR(255) NULL DEFAULT 'Halid Ibragimov',
    `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id` BIGINT(20) NULL DEFAULT NULL,
    `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
    `deleted` TINYINT(1) NULL DEFAULT '0',
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `md5` (`md5_hash` ASC) ,
    INDEX `run_id` (`run_id` ASC) ,
    INDEX `touched_run_id` (`touched_run_id` ASC) ,
    INDEX `deleted` (`deleted` ASC) ,
    INDEX `fk_il_tazewell__holding_facilities_il_tazewell__arrests1_idx` (`arrest_id` ASC) ,
    CONSTRAINT `fk_il_tazewell__holding_facilities_il_tazewell__arrests10`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`new_hampshire_arrests` (`id`)
     ON DELETE NO ACTION
     ON UPDATE NO ACTION
)
    ENGINE = InnoDB
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = '';

CREATE TABLE IF NOT EXISTS `new_hampshire_charges`
(
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `arrest_id` BIGINT(20) NULL DEFAULT NULL,
    `number` VARCHAR(255) NULL DEFAULT NULL,
    `disposition_date` DATE NULL DEFAULT NULL,
    `offense_date` DATE NULL DEFAULT NULL,
    `offense_time` TIME NULL DEFAULT NULL,
    `docket_number` VARCHAR(255) NULL DEFAULT NULL,
    `min_release_date` DATETIME NULL,
    `max_release_date` DATETIME NULL DEFAULT NULL,
    `data_source_url` TEXT NULL DEFAULT NULL,
    `created_by` VARCHAR(255) NULL DEFAULT 'Halid Ibragimov',
    `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id` BIGINT(20) NULL DEFAULT NULL,
    `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
    `deleted` TINYINT(1) NULL DEFAULT '0',
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `md5` (`md5_hash` ASC) ,
    INDEX `run_id` (`run_id` ASC) ,
    INDEX `touched_run_id` (`touched_run_id` ASC) ,
    INDEX `deleted` (`deleted` ASC) ,
    INDEX `fk_il_tazewell__charges_il_tazewell__arrests1_idx` (`arrest_id` ASC) ,
    CONSTRAINT `fk_il_tazewell__charges_il_tazewell__arrests10`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`new_hampshire_arrests` (`id`)
     ON DELETE NO ACTION
     ON UPDATE NO ACTION
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 2109
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = '';

CREATE TABLE IF NOT EXISTS `new_hampshire_court_hearings`
(
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `charge_id` BIGINT(20) NULL DEFAULT NULL,
    `court_name` VARCHAR(255) NULL DEFAULT NULL,
    `case_number` VARCHAR(255) NULL DEFAULT NULL,
    `data_source_url` TEXT NULL DEFAULT NULL,
    `created_by` VARCHAR(255) NULL DEFAULT 'Halid Ibragimov',
    `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id` BIGINT(20) NULL DEFAULT NULL,
    `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
    `deleted` TINYINT(1) NULL DEFAULT '0',
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `md5` (`md5_hash` ASC) ,
    INDEX `run_id` (`run_id` ASC) ,
    INDEX `touched_run_id` (`touched_run_id` ASC) ,
    INDEX `deleted` (`deleted` ASC) ,
    INDEX `fk_il_tazewell__court_hearings_il_tazewell__charges1_idx` (`charge_id` ASC) ,
    CONSTRAINT `fk_il_tazewell__court_hearings_il_tazewell__charges10`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`new_hampshire_charges` (`id`)
     ON DELETE NO ACTION
     ON UPDATE NO ACTION
)
    ENGINE = InnoDB
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = '';