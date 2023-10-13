CREATE TABLE `ustr`
(
    `id`              BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
    `title`			  VARCHAR(255),
    `teaser`		  TEXT,
    `article`		  LONGTEXT,
    `creator`		  VARCHAR(255)  DEFAULT 'Office of the U.S. Trade Representative',
    `date`			  DATETIME,
    `link`			  VARCHAR(500),
    `type`			  VARCHAR(255)  DEFAULT 'press release',
    `country`		  VARCHAR(255)  DEFAULT 'US',
    `data_source_url` VARCHAR(255)  DEFAULT 'https://ustr.gov/about-us/policy-offices/press-office/news',
    `dirty_news`      tinyint(1) DEFAULT 0,
    `with_table`      tinyint(1) DEFAULT 0,
    `created_by`      VARCHAR(255)       DEFAULT 'Pospelov Vyacheslav',
    `created_at`      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id`          BIGINT(20),
    `touched_run_id`  BIGINT,
    `deleted`         BOOLEAN           DEFAULT 0,
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`),
    UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;