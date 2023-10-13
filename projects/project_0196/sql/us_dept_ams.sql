CREATE TABLE `us_dept_ams`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`           varchar(1024), 
  `teaser`          text,
  `article`         longtext,
  `link`            varchar(600),
  `creator`         varchar(255) default "US Department of Agriculture",
  `type`            varchar(255) default "press releases",
  `country`         varchar (255) default "US",
  `release_no`      varchar(255),
  `contact_info`    varchar(1024),
  `date`            varchar(255),
  `dirty_news`      tinyint(1) default 0,
  `with_table`      tinyint(1) default 0,
  `data_source_url` varchar(255) DEFAULT "https://www.ams.usda.gov/news",
  `created_by`      VARCHAR(255)       DEFAULT "Abdur Rehman",
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

-- DROP TABLE us_dept_ams;