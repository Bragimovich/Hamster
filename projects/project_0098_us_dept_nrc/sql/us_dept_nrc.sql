CREATE TABLE `us_dept_nrc`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `title`           VARCHAR(1000),
  `teaser`          VARCHAR(2000),
  `article`         VARCHAR(5000),
  `link`            VARCHAR(300),
  `creator`         VARCHAR(255) default 'NRC Press Office',
  `type_article`    VARCHAR(50) default 'news',
  `city`            VARCHAR(50),
  `state`           VARCHAR(50),
  `country`         VARCHAR(50) default 'US',
  `date`            DATETIME,
  `release_no`      VARCHAR(50),
  `contact_info`    VARCHAR(700),
  `full`             INT(2),

  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

