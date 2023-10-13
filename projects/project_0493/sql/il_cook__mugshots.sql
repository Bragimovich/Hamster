create table `il_cook__mugshots`
(
  `id`              int auto_increment   primary key,
  `arrest_id`       int,
  `aws_link`        varchar (255),
  `original_link`   varchar (255),
  `run_id`          int,
  `md5_hash`        varchar (255),
  `touched_run_id`  BIGINT(20),
  `data_source_url` varchar (255),
  `deleted`         boolean            DEFAULT 0,
  `created_by`      VARCHAR(255)       DEFAULT 'Raza',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #493';
