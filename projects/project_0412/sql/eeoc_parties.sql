create table `eeoc_parties`
(
  `id`                   BIGINT(20) auto_increment   primary key,
  `run_id`               int,
  `touched_run_id`       BIGINT(20),
  `deleted`              boolean            DEFAULT 0,
  `case_id`              BIGINT(20),
  `brief_url`            varchar (255),
  `name`                 varchar (500),
  `type`                 varchar (255),
  `md5_hash`             varchar (255),
  `data_source_url`      varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Raza',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #412';
