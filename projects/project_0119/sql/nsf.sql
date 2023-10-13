CREATE TABLE `nsf`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title` VARCHAR(500),
  `teaser` TEXT,
  `article` longtext,
  `link` VARCHAR(255),
  `creator` varchar(255) DEFAULT 'National Science Foundation',
  `type` varchar(255),
  `kind` varchar(255),
  `release_no` varchar(255),
  `date` DATETIME null,
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