CREATE TABLE `us_dept_hca`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`           VARCHAR(1024),
  `teaser`          text,
  `article`         longtext,
  `creator`         VARCHAR(255)       DEFAULT 'US Department of HCA',
  `type`            VARCHAR(255)       DEFAULT 'press release',
  `country`         VARCHAR(255)       DEFAULT 'US',
  `date`            DATE,
  `dirty_news`      TINYINT(1),
  `with_table`      TINYINT(1),
  `link`            VARCHAR(255),
  `data_source_url` VARCHAR(255) DEFAULT 'https://agriculture.house.gov/news/',
  `created_by`      VARCHAR(255)       DEFAULT 'Raza Aslam',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
