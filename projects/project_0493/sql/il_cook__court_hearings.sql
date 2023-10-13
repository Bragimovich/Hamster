create table `il_cook__court_hearings`
(
  `id`               int auto_increment   primary key,
  `arrest_id`        int,
  `charge_id`        int DEFAULT null,
  `court_name`       varchar (255),
  `court_time`       time,
  `court_date`       date,
  `court_location`   varchar (255) DEFAULT NULL,
  `court_room`       varchar (255) DEFAULT NULL,
  `case_number`      varchar (255) DEFAULT NULL,
  `type`             varchar (255) DEFAULT NULL,
  `touched_run_id`   BIGINT(20),
  `run_id`           int,
  `md5_hash`         varchar (255),
  `data_source_url`  varchar (255),
  `deleted`          boolean          DEFAULT 0,
  `created_by`       VARCHAR(255)     DEFAULT 'Raza',
  `created_at`       DATETIME         DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #493';
