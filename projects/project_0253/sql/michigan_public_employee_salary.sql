CREATE TABLE `michigan_public_employee_salary`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                    BIGINT(20),
  `full_name`                 VARCHAR (255),
  `first_name`                VARCHAR (255),
  `last_name`                 VARCHAR (255),
  `middle_name`               VARCHAR (255),
  `employer`                  VARCHAR (255),
  `job`                       VARCHAR (255),
  `year`                      VARCHAR (255),
  `salary`                    DECIMAL (15,2),
  `data_source_url`           VARCHAR(255)      DEFAULT 'https://www.mackinac.org/salaries?report=any&search=any&sort=wage2018-desc&filter=',
  `created_by`                VARCHAR(255)      DEFAULT 'Aqeel',
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`            BIGINT,
  `deleted`                   BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255)GENERATED ALWAYS AS (md5(concat_ws('',full_name,first_name,last_name,middle_name,employer,job,year,salary))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Aqeel Anwar';
