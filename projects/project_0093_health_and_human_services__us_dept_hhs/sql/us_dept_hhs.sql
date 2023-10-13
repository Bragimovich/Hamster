CREATE TABLE `us_dept_hhs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `title`           VARCHAR(1000),
  `title_id`        VARCHAR(50),
  `teaser`          VARCHAR(2000),
  `article`         VARCHAR(4000),
  `link`            VARCHAR(300),
  `creator`         VARCHAR(255) default 'HHS Press Office',
  `type_article`            VARCHAR(50),
  `country`         VARCHAR(50) default 'US',
  `date`            DATETIME,
  `contact_info`    VARCHAR(700),

  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

