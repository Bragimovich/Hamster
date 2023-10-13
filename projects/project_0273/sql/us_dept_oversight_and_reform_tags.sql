create table `us_dept_oversight_and_reform_tags`
(
  `id`                   int auto_increment   primary key,
  `tag`                  varchar(255),
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`tag`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
