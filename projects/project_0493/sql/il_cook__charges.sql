create table `il_cook__charges`
(
  `id`                 int auto_increment   primary key,
  `arrestee_id`        int,
  `number`             varchar (255),
  `disposition`        varchar (255),
  `disposition_date`   varchar (255),
  `description`        varchar (255),
  `offense_date`       varchar (255),
  `offense_time`       varchar (255),
  `attempt_or_commit`  varchar (255),
  `docket_number`      varchar (255),
  `touched_run_id`     BIGINT(20),
  `run_id`             int,
  `md5_hash`           varchar (255),
  `data_source_url`    varchar (255),
  `deleted`            boolean          DEFAULT 0,
  `created_by`         VARCHAR(255)     DEFAULT 'Raza',
  `created_at`         DATETIME         DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #493';
