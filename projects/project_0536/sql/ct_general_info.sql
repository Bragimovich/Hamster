CREATE TABLE ct_general_info(
  `id`	bigint(20) AUTO_INCREMENT PRIMARY KEY,
  `is_district`	      bigint(10),
  `district_id`	      bigint(20),
  `number`	          varchar(50),
  `name`	            varchar(255),
  `type`	            varchar(255),
  `low_grade`	           varchar(255),
  `high_grade`	         varchar(255),
  `charter`              varchar(255),
  `magnet`               varchar(255),
  `title_1_school`       varchar(255),
  `title_1_school_wide`  varchar(255),
  `nces_id`	           varchar(50),
  `program_type`	     varchar(255),
  `education_program`	 varchar(255),
  `phone`	      varchar(255),
  `county`      varchar(255),
  `address`	    varchar(255),
  `city`	      varchar(255),
  `state`	      varchar(255),
  `zip`	        varchar(255),
  `zip_4`        varchar(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Abur Rehman',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  touched_run_id  BIGINT,
  deleted         BOOLEAN           DEFAULT 0,
  md5_hash        VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
