create table `us_dept_fcc_categories`
(
  `id`                  BIGINT auto_increment   primary key,
  `category`            VARCHAR(255) ,
  `created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`category`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
