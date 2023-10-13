CREATE TABLE `us_dept_committee_on_natural_resources`
(
  `id`              BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  `title`			      VARCHAR(255),
  `teaser`			    TEXT,
  `article`			    LONGTEXT,
  `link`			      VARCHAR(255),
  `creator`			    VARCHAR(255)  DEFAULT 'The Republican House Committee on Natural Resources',
  `type`			      VARCHAR(255)  DEFAULT 'press release',
  `country`			    VARCHAR(255)  DEFAULT 'US',
  `date`			      DATETIME,
  `contact_info`    VARCHAR(255),
  `dirty_news`			TINYINT(1)    DEFAULT 0, /* FALSE */
  `with_table`			TINYINT(1)    DEFAULT 0, /* FALSE */
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)  DEFAULT 'Oleksii Kuts',
  `created_at`      DATETIME      DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
