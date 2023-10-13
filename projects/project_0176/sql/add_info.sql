create table `mi_saac_case_additional_info`
(
  `id`  int auto_increment   primary key,
  `court_id`  int,
  `case_id`  varchar (255),
  `lower_court_name`  varchar (255),
  `lower_case_id`  varchar (255),
  `lower_judge_name`  varchar (255),
  `lower_link`  varchar (255),
  `disposition`  varchar (255),
  `md5_hash`  varchar (255),
  `data_source_url`     varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;


