CREATE TABLE `congressional_record_departments_keywords_test`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `department`      varchar(255)                        null,
    `dept_id`         BIGINT(20),
    `keyword`         varchar(255)                        null,
    `value`           INT                 default 1,


    `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX `dept_id` (`dept_id`),
    INDEX `keyword` (`keyword`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
