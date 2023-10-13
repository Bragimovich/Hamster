CREATE TABLE `us_dept_scoepw_press_releases`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`           VARCHAR(1000),
  `teaser`          VARCHAR(2000),
  `article`         longtext,
  `link`            VARCHAR(300),
  `creator`         VARCHAR(255) default 'Senate Committee on Environment and Public Work',
  `type_article`    VARCHAR(50) default 'press release',
  `country`         VARCHAR(50) default 'US',
  `date`            DATETIME,
  `contact_info`    VARCHAR(700),
  `dirty_news`      TINYINT(1),
  `with_table`      TINYINT(1),

  `data_source_url` VARCHAR(255)       DEFAULT 'https://www.epw.senate.gov/public/index.cfm/press-releases-republican',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,


  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
