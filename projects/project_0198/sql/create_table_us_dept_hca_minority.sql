CREATE TABLE `us_dept_hca_minority`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title`           VARCHAR(255),
  `teaser`          TEXT,
  `article`         LONGTEXT,
  `link`            VARCHAR(400),
  `creator`         VARCHAR(255)        DEFAULT 'US Department of HCA',
  `type`            VARCHAR(255)        DEFAULT 'press release',
  `country`         VARCHAR(255)        DEFAULT 'US',
  `date`            DATETIME,
  `dirty_news`      BOOLEAN,
  `with_table`      BOOLEAN,
  `data_source_url` VARCHAR(255)       DEFAULT 'https://www.hsgac.senate.gov/media/minority-media',
  `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN            DEFAULT 0,
  UNIQUE KEY `link` (`link`),
  INDEX `run_id` (`run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
