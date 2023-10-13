create table `eeoc_briefs`
(
  `id`                   BIGINT(20) auto_increment primary key,
  `run_id`               int,
  `touched_run_id`       BIGINT(20),
  `deleted`              boolean            DEFAULT 0,
  `case_nr`              VARCHAR(255),
  `case_title`           varchar(255),
  `date_filled`          DATE,
  `brief_type`           varchar (255),
  `case_court`           varchar (255),
  `case_url`             varchar (255),
  `statuses`             varchar (255),
  `data_source_url`      varchar (255),
  `bases`                varchar (255),
  `read_brief_url`       varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Raza',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`             VARCHAR(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', case_title, case_nr, case_url, date_filled, brief_type, statuses, bases, case_court, read_brief_url))) STORED,
  UNIQUE KEY `unique_data` (`case_url`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #412';
