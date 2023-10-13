CREATE TABLE ky_general_info (
  `id` 					BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `county_number` 		VARCHAR(50),
  `is_district` 		TINYINT(1),
  `district_id`			INT,
  `number` 				VARCHAR(50),
  `name` 				VARCHAR(255),
  `school_code` 		VARCHAR(50),
  `state_school_id` 	VARCHAR(50),
  `nces_id` 			VARCHAR(50),
  `coop_code` 			VARCHAR(50),
  `coop_name` 			VARCHAR(255),
  `school_type` 		VARCHAR(255) CHARACTER SET 'ascii',
  `low_grade` 			VARCHAR(255),
  `high_grade` 			VARCHAR(255),
  `title_1_status` 		VARCHAR(255),
  `program_type` 		VARCHAR(255),
  `education_program`	VARCHAR(255),
  `locale` 				VARCHAR(255),
  `phone` 				VARCHAR(255),
  `fax` 				VARCHAR(255),
  `website` 			VARCHAR(255),
  `address` 			VARCHAR(255),
  `city` 				VARCHAR(255),
  `county` 				VARCHAR(255),
  `state` 				VARCHAR(255),
  `zip` 				VARCHAR(255),
  `lat` 				VARCHAR(255),
  `lon` 				VARCHAR(255),
   `data_source_url` 	TEXT,
  `created_by`     		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT,
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
    
    CREATE TABLE ky_administrators (
  `id` 					INT(20) AUTO_INCREMENT PRIMARY KEY ,
  `general_id` 			BIGINT ,
  `role` 				VARCHAR(255) NULL,
  `full_name` 			VARCHAR(255) NULL,
  `first_name` 			VARCHAR(255) NULL,
  `last_name` 			VARCHAR(255) NULL,
  `school_year`			VARCHAR(255) NULL,
  `email` 				VARCHAR(255) NULL,
   `data_source_url` 	TEXT,
  `created_by`     		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT,
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`),
  INDEX `administrator_school_number_idx` (`general_id` ASC),
  CONSTRAINT `administrator_school_number`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
    
    
    CREATE TABLE ky_enrollment (
  `id` 					INT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 			BIGINT,
  `school_year` 		VARCHAR(50),
  `grade` 				VARCHAR(255),
  `demographic` 		VARCHAR(255),
  `count` 				VARCHAR(255),
  `percent`				VARCHAR(255),
  `suppressed` 			VARCHAR(255),
  `dropout_count`		VARCHAR(255),
  `dropout_membership`	VARCHAR(255),
  `dropout_rate`		VARCHAR(255),
  `data_source_url` 	TEXT,
  `created_by`     		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT,
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`),
  INDEX `schools_enrollment_idx` (`general_id` ASC),
  CONSTRAINT `schools_enrollment`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
    
    CREATE TABLE ky_schools_assessment (
  `id` 					BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 			BIGINT,
  `school_year` 		VARCHAR(45),
  `exam_name` 			VARCHAR(255),
  `grade` 				VARCHAR(255),
  `subject` 			VARCHAR(255),
  `demographic` 		VARCHAR(255),
  `number_of_students` 	VARCHAR(255),
  `number_tested` 		VARCHAR(255),
  `percent_rate` 		VARCHAR(255),
  `with_scored` 		VARCHAR(255),
  `average_score` 		VARCHAR(255),
  `data_source_url` 	TEXT,
  `created_by`     		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT,
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`),
  INDEX `assessment_ssa_index_school_idx` (`general_id` ASC) ,
  CONSTRAINT `assessment_ssa_index_school`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';

CREATE TABLE ky_schools_assessment_by_levels (
  `id`					BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `assessment_id` 		BIGINT,
  `level` 				VARCHAR(255),
  `count` 				VARCHAR(255),
  `percent` 			VARCHAR(255),
  `data_source_url` 	TEXT,
  `created_by`     		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT,
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`),
  INDEX `level_ssa_index_idx` (`assessment_id` ASC) ,
  CONSTRAINT `level_ssa_index`
    FOREIGN KEY (`assessment_id`)
    REFERENCES `us_schools_raw`.`ky_schools_assessment` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
    
    
    CREATE TABLE ky_assessment_act (
  `id` 					BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 			BIGINT,
  `school_year` 		VARCHAR(50),
  `subject` 			VARCHAR(255),
  `tested_count`		VARCHAR(255),
  `demographic` 		VARCHAR(255),
  `suppressed_average`	VARCHAR(255),
  `average_act_scores` 	VARCHAR(255),
  `suppressed_benchmarks`	VARCHAR(255),
  `percent_meeting_benchmarks` VARCHAR(255),
  `data_source_url` 	TEXT,
  `created_by`     		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT,
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`),
  INDEX `act_scores_school_idx` (`general_id` ASC),
  CONSTRAINT `act_scores_school`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
    
    CREATE TABLE ky_assesment_national (
  `id` 							BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `school_year` 				VARCHAR(50),
  `grade` 						VARCHAR(255),
  `subject` 					VARCHAR(255),
  `demographic` 				VARCHAR(255),
  `level` 						VARCHAR(255),
  `percent_below_basic_level` 	VARCHAR(255),
  `percent_at_basic_level` 		VARCHAR(255),
  `percent_procient` 			VARCHAR(255),
  `percent_at_advanced_level` 	VARCHAR(255),
  `parcipation_rate` 			VARCHAR(255),
   `data_source_url` 			TEXT,
  `created_by`     				VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          			BIGINT(20),
  `touched_run_id`  			BIGINT,
  `deleted`         			BOOLEAN           DEFAULT 0,
  `md5_hash`        			VARCHAR(255),
  UNIQUE KEY        			`md5` (`md5_hash`),
  INDEX             			`run_id` (`run_id`),
  INDEX             			`touched_run_id` (`touched_run_id`),
  INDEX             			`deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
    
    
    CREATE TABLE ky_graduation_rate (
  `id` 							BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id`					BIGINT,
  `school_year` 				VARCHAR(50),
  `graduation_type` 			VARCHAR(255),
  `demographic` 				VARCHAR(255),
  `target_label`				VARCHAR(255),
  `suppressed` 					VARCHAR(255),
  `number_of_grads`				VARCHAR(255),
  `number_of_students`   		VARCHAR(255),
  `graduation_rate` 			VARCHAR(255),
   `data_source_url` 			TEXT,
  `created_by`     				VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          			BIGINT(20),
  `touched_run_id`  			BIGINT,
  `deleted`         			BOOLEAN           DEFAULT 0,
  `md5_hash`        			VARCHAR(255),
  UNIQUE KEY        			`md5` (`md5_hash`),
  INDEX             			`run_id` (`run_id`),
  INDEX             			`touched_run_id` (`touched_run_id`),
  INDEX             			`deleted` (`deleted`),
  INDEX `graduation_general_idx` (`general_id` ASC),
  CONSTRAINT `graduation_general`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';    
    
    
    CREATE TABLE ky_safety_events (
  `id` 							      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 					  BIGINT,
  `school_year` 				  VARCHAR(50),
  `demographic`					  VARCHAR(255),
  `group` 						    VARCHAR(255),
  `name` 						      VARCHAR(255),
  `count` 						    VARCHAR(255),
   `data_source_url` 			TEXT,
  `created_by`     				VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          			BIGINT(20),
  `touched_run_id`  			BIGINT,
  `deleted`         			BOOLEAN           DEFAULT 0,
  `md5_hash`        			VARCHAR(255),
  UNIQUE KEY        			`md5` (`md5_hash`),
  INDEX             			`run_id` (`run_id`),
  INDEX             			`touched_run_id` (`touched_run_id`),
  INDEX             			`deleted` (`deleted`),
  INDEX `events_general_idx` (`general_id` ASC),
  CONSTRAINT `events_general`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';   
    
    
    CREATE TABLE ky_safety_climate_index (
  `id` 							      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 					  BIGINT,
  `school_year` 				  VARCHAR(50),
  `level` 						    VARCHAR(255),
  `demographic` 				  VARCHAR(255),
  `suppressed` 					  VARCHAR(255),
  `climate_index` 				VARCHAR(255),
  `safety_index` 				  VARCHAR(255),
  `data_source_url` 			TEXT,
  `created_by`     				VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          			BIGINT(20),
  `touched_run_id`  			BIGINT,
  `deleted`         			BOOLEAN           DEFAULT 0,
  `md5_hash`        			VARCHAR(255),
  UNIQUE KEY        			`md5` (`md5_hash`),
  INDEX             			`run_id` (`run_id`),
  INDEX             			`touched_run_id` (`touched_run_id`),
  INDEX             			`deleted` (`deleted`),
  INDEX `index_climate_safety_geranal_idx` (`general_id` ASC),
  CONSTRAINT `index_climate_safety_geranal`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539'; 


CREATE TABLE ky_safety_climate (
  `id` 							      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 					  BIGINT,
  `school_year` 				  VARCHAR(50),
  `level` 						    VARCHAR(255),
  `demographic` 				  VARCHAR(255),
  `question_number` 			VARCHAR(255),
  `question_type` 				VARCHAR(255),
  `question` 					    VARCHAR(255),
  `suppressed` 					  VARCHAR(255),
  `strongly_disagree` 		VARCHAR(255),
  `disagree` 					    VARCHAR(255),
  `agree` 						    VARCHAR(255),
  `strongly_agree` 				VARCHAR(255),
  `agree_and_strongly_agree` 	VARCHAR(255),
  `question_index` 				VARCHAR(255),
   `data_source_url` 			TEXT,
  `created_by`     				VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          			BIGINT(20),
  `touched_run_id`  			BIGINT,
  `deleted`         			BOOLEAN           DEFAULT 0,
  `md5_hash`        			VARCHAR(255),
  UNIQUE KEY        			`md5` (`md5_hash`),
  INDEX             			`run_id` (`run_id`),
  INDEX             			`touched_run_id` (`touched_run_id`),
  INDEX             			`deleted` (`deleted`),
  INDEX `safety_climate_general_idx` (`general_id` ASC),
  CONSTRAINT `safety_climate_general`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539'; 
    
    
    CREATE TABLE ky_safety_audit (
  `id` 							      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 					  BIGINT,
  `school_year` 				  VARCHAR(50),
  `safety_audit` 				  VARCHAR(255),
  `date` 						      DATE,
   `data_source_url` 			TEXT,
  `created_by`     				VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          			BIGINT(20),
  `touched_run_id`  			BIGINT,
  `deleted`         			BOOLEAN           DEFAULT 0,
  `md5_hash`        			VARCHAR(255),
  UNIQUE KEY        			`md5` (`md5_hash`),
  INDEX             			`run_id` (`run_id`),
  INDEX             			`touched_run_id` (`touched_run_id`),
  INDEX             			`deleted` (`deleted`),
  INDEX `safety_audit_general_idx` (`general_id` ASC),
  CONSTRAINT `safety_audit_general`
    FOREIGN KEY (`general_id`)
    REFERENCES `us_schools_raw`.`ky_general_info` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #539';
