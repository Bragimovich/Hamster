CREATE TABLE `us_dept_frs_categories`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `category` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Eldar M.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   UNIQUE KEY `category` (`category`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

ALTER TABLE us_dept_frs_categories ALTER COLUMN created_by SET DEFAULT 'Oleksii Kuts';
ALTER TABLE us_dept_frs_categories COMMENT 'Categories of press releases, speeches and tesimonies from federalreserve.gov, Created by Eldar M., Updated by Oleksii Kuts, Task #107';
