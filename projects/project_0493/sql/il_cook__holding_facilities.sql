create table `il_cook__holding_facilities`
(
  `id`                    int auto_increment   primary key,
  `arrest_id`             int,
  `planned_release_date`  date,
  `actual_release_date`   date,
  `start_date`            date,
  `facility`              varchar (255) DEFAULT NULL,
  `facility_type`         varchar (255) DEFAULT NULL,
  `facility_subtype`      varchar (255) DEFAULT NULL,
  `md5_hash`              varchar (255),
  `touched_run_id`        BIGINT(20),
  `run_id`                int,
  `data_source_url`       varchar (255),
  `deleted`               boolean            DEFAULT 0,
  `created_by`            VARCHAR(255)       DEFAULT 'Raza',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #493';
