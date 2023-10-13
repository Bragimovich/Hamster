CREATE TABLE `us_dept_scoenr_democratic`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`           VARCHAR(1000),
  `teaser`          VARCHAR(2000),
  `article`         longtext,
  `link`            VARCHAR(300),
  `creator`         VARCHAR(255) default 'Senate Committee On Energy & Natural Resources',
  `type_article`    VARCHAR(50) default 'news',
  `country`         VARCHAR(50) default 'US',
  `date`            DATETIME,
  `contact_info`    VARCHAR(700),
  `dirty_news`      TINYINT(1) default 0,
  `with_table`      TINYINT(1) default 0,

  `data_source_url` VARCHAR(255)       DEFAULT 'https://www.energy.senate.gov/democratic-news ',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
