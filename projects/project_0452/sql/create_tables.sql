CREATE TABLE `sba`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  # begin
  `title`			      VARCHAR(255), /* title */
  `subtitle`	      VARCHAR(255), /* summary*/
  `teaser`			    TEXT,         /* first paragraph */
  `article`			    LONGTEXT,     /* full text with html tags */
  /* office */
  `creator`			    VARCHAR(255)  DEFAULT 'Small Business Administration',

  `date`			      DATETIME,     /* parse link */
  `link`			      VARCHAR(255), /* url */
  `release_number`  VARCHAR(255), /* if present in article page */
  `program`         VARCHAR(255), /* programs.join('/') */
  `contact_info`    VARCHAR(255), /* if present in article page */
  `type`			      VARCHAR(255)  DEFAULT 'press release', /* category */
  `country`			    VARCHAR(255)  DEFAULT 'US',
  `dirty_news`			TINYINT(1)    DEFAULT 0, /* FALSE */
  `with_table`			TINYINT(1)    DEFAULT 0, /* 1 if espanol */
  # end
  `data_source_url` VARCHAR(255)  DEFAULT 'https://www.sba.gov/',
  `created_by`      VARCHAR(255)  DEFAULT 'Oleksii Kuts',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
