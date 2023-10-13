CREATE TABLE `ga_employee_compensation`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `full_name`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `middle_name`     VARCHAR(255),
  `last_name`       VARCHAR(255),
  `title`           VARCHAR(255),
  `salary`          decimal(10,3),
  `travel`          decimal(10,3),
  `organization`    VARCHAR(255),
  `fiscal_year`     int(11),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aqeel',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR (255)GENERATED ALWAYS AS (md5(concat_ws('',full_name,first_name,middle_name,last_name,title,salary,travel,organization,fiscal_year))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
 COLLATE = utf8mb4_unicode_520_ci;
