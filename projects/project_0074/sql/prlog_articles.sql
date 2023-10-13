CREATE TABLE `prlog_articles`
(
    `prlog_id`              BIGINT(20) PRIMARY KEY,
    `title`				VARCHAR(255),
    `teaser`				TEXT,
    `article`             LONGTEXT,
    `arcticle_link`	    VARCHAR(255),
    `creator`			    VARCHAR(255),
    `city`				VARCHAR(255),
    `state`				VARCHAR(255),
    `country`			    VARCHAR(255) DEFAULT 'US',
    `date`				DATETIME,
    `contact_info`		VARCHAR(255),
    `run_id`          bigint                                        null,
    `touched_run_id`  bigint                                        null,
    `deleted`         tinyint(1)   default 0                        null,
    `data_source_url` varchar(255) default 'https://www.prlog.org/' null,
    `created_by`      varchar(255) default 'Maxim G'                null,
    `updated_at`      datetime     default CURRENT_TIMESTAMP        not null,
    `created_at`      datetime     default CURRENT_TIMESTAMP        not null

) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
