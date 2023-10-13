CREATE TABLE `congressional_record_article_to_departments_keywords_test`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `article_id`      BIGINT(20),
  `dept_id`         BIGINT(20),
  `keyword`         varchar(511),
  `date`            datetime,


  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `article_id` (`article_id`),
  INDEX `dept_id` (`dept_id`),
  INDEX `keyword` (`keyword`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
