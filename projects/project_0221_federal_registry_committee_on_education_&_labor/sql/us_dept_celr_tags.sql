CREATE TABLE `us_dept_celr_tags`
(
`id`                  bigint auto_increment   primary key,
`tag`                 varchar(255),
`created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
`created_at`          DATETIME           ,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`tag`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  