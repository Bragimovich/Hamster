CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_arrestees` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `full_name` 				VARCHAR(255) NOT NULL,
  `first_name`				VARCHAR(255) NOT NULL DEFAULT '',
  `middle_name` 			VARCHAR(255) NOT NULL DEFAULT '',
  `last_name` 				VARCHAR(255) NOT NULL DEFAULT '',
  `suffix` 					VARCHAR(255) NOT NULL DEFAULT '',
  `birthdate` 				DATETIME NOT NULL DEFAULT 0,
  `age` 					INT NOT NULL DEFAULT -1,
  `race` 					VARCHAR(45) NOT NULL DEFAULT 'unknown',
  `sex` 					VARCHAR(45) NOT NULL DEFAULT 'unknown',
  `height` 					VARCHAR(45) NULL DEFAULT 'unknown',
  `weight` 					VARCHAR(45) NULL DEFAULT 'unknown',
  `eye_color` 				VARCHAR(45) NOT NULL DEFAULT 'unknown',
  `hair_color` 				VARCHAR(45) NOT NULL DEFAULT 'unknown',
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';


CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_advance_arrestees` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `designation` 			VARCHAR(128) NOT NULL,
  `dept_of_corrections` 	VARCHAR(1000) NOT NULL DEFAULT 'unknown',
  `model` 					VARCHAR(255) NOT NULL DEFAULT '',
  `status` 					VARCHAR(45) NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  UNIQUE INDEX 				`id_UNIQUE` (`id` ASC),
  INDEX 					`fk_offense_arrestees1_idx` (`arrestee_id` ASC),
  CONSTRAINT 				`fk_offense_arrestees120`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_arrestee_aliases` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `alias_full_name` 		VARCHAR(255) NOT NULL,
  `alias_first_name` 		VARCHAR(255) NOT NULL DEFAULT '',
  `alias_middle_name` 		VARCHAR(255) NOT NULL DEFAULT '',
  `alias_last_name` 		VARCHAR(255) NOT NULL DEFAULT '',
  `alias_suffix` 			VARCHAR(255) NOT NULL DEFAULT '',
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  INDEX `fk_arrestee_aliases_arrestees1_idx` (`arrestee_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  CONSTRAINT `fk_arrestee_aliases_arrestees1`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_makrs` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `type_marks`				VARCHAR(255) NULL,
  `body_location` 			VARCHAR(255) NULL,
  `smt_count` 				INT NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `fk_offense_arrestees1_idx` (`arrestee_id` ASC),
  CONSTRAINT `fk_offense_arrestees11`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    

    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_vehicles_info` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `type_vehicles` 			VARCHAR(128) NOT NULL,
  `make` 					VARCHAR(1000) NOT NULL DEFAULT 'unknown',
  `model` 					VARCHAR(255) NOT NULL DEFAULT '',
  `color` 					VARCHAR(45) NULL,
  `registration` 			VARCHAR(128) NULL,
  `year` 					VARCHAR(45) NULL,
  `body` 					VARCHAR(45) NULL,
  `states_id` 				BIGINT(20) NOT NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `fk_offense_arrestees1_idx` (`arrestee_id` ASC),
  INDEX `fk_offense_states1_idx` (`states_id` ASC),
  CONSTRAINT `fk_offense_arrestees12`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_offense_states10`
    FOREIGN KEY (`states_id`)
    REFERENCES `sex_offenders`.`florida_states` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554, registration - number_reg_car';
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_offense` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `date` 					DATE NOT NULL,
  `description` 			VARCHAR(1000) NOT NULL DEFAULT 'unknown',
  `case_number` 			VARCHAR(255) NOT NULL DEFAULT '',
  `adjudication`			VARCHAR(45) NULL,
  `states_id` 				BIGINT(20) NOT NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `fk_offense_arrestees1_idx` (`arrestee_id` ASC),
  INDEX `fk_offense_states1_idx` (`states_id` ASC),
  CONSTRAINT `fk_offense_arrestees1`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_offense_states1`
    FOREIGN KEY (`states_id`)
    REFERENCES `sex_offenders`.`florida_states` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    
CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_addresses` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `full_address` 			VARCHAR(1000) NOT NULL,
  `cities_id` 				BIGINT(20) NOT NULL,
  `zips_id` 				BIGINT(20) NOT NULL,
  `states_id` 				BIGINT(20) NOT NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  INDEX `cities_idx` (`cities_id` ASC),
  INDEX `zips_idx` (`zips_id` ASC),
  INDEX `states_idx` (`states_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  CONSTRAINT `fk_addresses_cities`
    FOREIGN KEY (`cities_id`)
    REFERENCES `sex_offenders`.`florida_cities` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_addresses_zips`
    FOREIGN KEY (`zips_id`)
    REFERENCES `sex_offenders`.`florida_zips` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_addresses_states`
    FOREIGN KEY (`states_id`)
    REFERENCES `sex_offenders`.`florida_states` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_victim_info` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `gender` 					VARCHAR(256) NULL,
  `minor` 					VARCHAR(256) NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  INDEX `fk_reg_information_arrestees1_idx` (`arrestee_id` ASC),
  CONSTRAINT `fk_reg_information_arrestees10`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';

CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_states` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `name` 					VARCHAR(255) NOT NULL,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';


CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_cities` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `name` 					VARCHAR(1000) NOT NULL,
  `states_id`				BIGINT(20) NOT NULL,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX `fk_cities_states1_idx` (`states_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  CONSTRAINT `fk_cities_states1`
    FOREIGN KEY (`states_id`)
    REFERENCES `sex_offenders`.`florida_states` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';

CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_zips` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `code` 					VARCHAR(45) NOT NULL,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';

    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_arrestees_address` (
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `addresses_id` 			BIGINT(20) NOT NULL,
  UNIQUE KEY `arrestee_id` (`arrestee_id`,`addresses_id`),
  INDEX `addresses_idx` (`addresses_id` ASC),
  INDEX `fk_arrestees_address_arrestees1_idx` (`arrestee_id` ASC),
  CONSTRAINT `fk_arrestees_address_addresses1`
    FOREIGN KEY (`addresses_id`)
    REFERENCES `sex_offenders`.`florida_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_arrestees_address_arrestees1`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_vessel_info` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT(20) NOT NULL,
  `make` 					VARCHAR(1000) NOT NULL DEFAULT 'unknown',
  `vessel_type` 			VARCHAR(255) NOT NULL DEFAULT '',
  `color` 					VARCHAR(45) NULL,
  `motor_type` 				VARCHAR(45) NULL,
  `hull_material`			VARCHAR(45) NULL,
  `registration` 			VARCHAR(128) NULL,
  `year` 					VARCHAR(45) NULL,
  `states_id` 				BIGINT(20) NOT NULL,
   `data_source_url` 		TEXT,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `fk_offense_arrestees1_idx` (`arrestee_id` ASC),
  INDEX `fk_offense_states1_idx` (`states_id` ASC),
  CONSTRAINT `fk_offense_arrestees121`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_offense_states100`
    FOREIGN KEY (`states_id`)
    REFERENCES `sex_offenders`.`florida_states` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_mugshots` (
  `id` 						BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id` 			BIGINT NOT NULL,
  `aws_link` 				VARCHAR(255),
  `original_link` 			VARCHAR(255),
  `data_source_url` 		TEXT,
  `date` 					DATETIME NOT NULL DEFAULT 0,
  `created_by`     			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          		BIGINT(20),
  `touched_run_id`  		BIGINT,
  `deleted`         		BOOLEAN           DEFAULT 0,
  `md5_hash`        		VARCHAR(255),
  UNIQUE KEY        		`md5` (`md5_hash`),
  INDEX             		`run_id` (`run_id`),
  INDEX             		`touched_run_id` (`touched_run_id`),
  INDEX             		`deleted` (`deleted`),
  INDEX `fk_mugshots_arrestees1_idx` (`arrestee_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  CONSTRAINT `fk_mugshots_arrestees1`
    FOREIGN KEY (`arrestee_id`)
    REFERENCES `sex_offenders`.`florida_arrestees` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #554';
    
    
    CREATE TABLE IF NOT EXISTS `sex_offenders`.`florida_runs` 
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Linnik Victor',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Victor Linnik, Task #554';
