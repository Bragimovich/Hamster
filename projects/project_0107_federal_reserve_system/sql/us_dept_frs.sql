CREATE TABLE `us_dept_frs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title` VARCHAR(255),
  `teaser` TEXT,
  `article` longtext,
  `link` VARCHAR(255),
  `creator` varchar(255) DEFAULT 'Board of Governors of the Federal Reserve System',
  `type` varchar(255),
  `country` varchar(255) default 'US',
  `date` DATETIME null,
  `bureau_office` longtext,
  `contact_info` longtext,
  `scrape_frequency` varchar(255)                       DEFAULT 'daily',
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Eldar M.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`),
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

ALTER TABLE us_dept_frs ALTER COLUMN created_by SET DEFAULT 'Oleksii Kuts';
ALTER TABLE us_dept_frs COMMENT 'Press releases, speeches and tesimonies from federalreserve.gov, Created by Eldar M., Updated by Oleksii Kuts, Task #107'
