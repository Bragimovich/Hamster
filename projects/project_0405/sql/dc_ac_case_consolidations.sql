create table `dc_ac_case_consolidations`
(
  `id`                             INT auto_increment   primary key,
  `court_id`                       INT,
  `case_id`                        VARCHAR (255),
  `consolidated_case_id`           VARCHAR (255),
  `consolidated_case_name`         VARCHAR (255),
  `consolidated_case_filled_date`  DATE,
  `md5_hash`                       VARCHAR (255),
  `data_source_url`                VARCHAR (255),
  `created_by`                     VARCHAR (255)       DEFAULT 'Adeel',
  `created_at`                     DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
