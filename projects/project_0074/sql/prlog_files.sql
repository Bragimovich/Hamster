use press_releases;
CREATE TABLE `prlog_files`
(
    `prlog_id`              BIGINT(20) PRIMARY KEY,
    `title`				VARCHAR(255),
    `link`			    VARCHAR(255)

) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
