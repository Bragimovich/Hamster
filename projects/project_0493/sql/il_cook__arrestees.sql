create table `il_cook__arrestees`
(
  `id`             int auto_increment   primary key,
  `full_name`      varchar (255),
  `first_name`     varchar (255),
  `middle_name`    varchar (255),
  `last_name`      varchar (255),
  `suffix`         varchar (255) DEFAULT NULL,
  `race`           varchar (255) DEFAULT NULL,
  `sex`            varchar (255) DEFAULT NULL,
  `height`         varchar (255) DEFAULT NULL,
  `weight`         varchar (255) DEFAULT NULL,
  `birthdate`      date  DEFAULT NULL,
  `run_id`         int,
  `touched_run_id` BIGINT(20),
  `age`            int,
  `age_as_of_date` int,
  `md5_hash`       varchar (255),
  `data_source_url`varchar (255),
  `deleted`        boolean          DEFAULT 0,
  `created_by`     VARCHAR(255)     DEFAULT 'Raza',
  `created_at`     DATETIME         DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #493';
