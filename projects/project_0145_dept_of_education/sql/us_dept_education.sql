CREATE TABLE `press_releases.us_dept_education`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `title`           VARCHAR(500),
  `teaser`          VARCHAR(1000),
  `article`         VARCHAR(5000),
  `link`            VARCHAR(300),
  `creator`         VARCHAR(255)       DEFAULT 'U.S. Dept. of Education',
  `type`            VARCHAR(100)       DEFAULT 'press release',
  `country`         VARCHAR(50)        DEFAULT 'US',
  `date`            DATETIME,
  `contact_info`    VARCHAR(700),

  `data_source_url` VARHCAR(255)       DEFAULT 'https://www.ed.gov/news/press-releases',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

create index link
	on us_dept_education (link);

