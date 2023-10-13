create table `ca_kcsc_case_pdfs_on_aws`
(
  `id`                  int auto_increment   primary key,
  `court_id`            int,
  `case_id`             varchar (255),
  `source_type`         varchar (255),
  `aws_link`            varchar (255),
  `source_link`         varchar (255),
  `md5_hash`            varchar (255),
  `run_id`              int,
  `touched_run_id`      BIGINT,
  `deleted`             tinyint(1) DEFAULT 0,
  `data_source_url`     varchar (255),
  `created_by`          VARCHAR(255)       DEFAULT 'Asim Saeed',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Asim Saeed, Task #0644';
