CREATE TABLE `pr_com_articles`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`			VARCHAR(255),
  `teaser`			TEXT,
  `article`			LONGTEXT,
  `link`			VARCHAR(255),
  `creator`			VARCHAR(255),
  `city`			VARCHAR(255),
  `state`			VARCHAR(255),
  `country`			VARCHAR(255) DEFAULT 'US',
  `date`			DATETIME,
  `contact_info`	VARCHAR(255),
  `transferred`     BOOLEAN DEFAULT 0,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Anton Storchak',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `pr_com_files`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `pr_come_id`		BIGINT,
  `title`			VARCHAR(255),
  `link`			VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Anton Storchak',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `pr_com_categories`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `category`	      VARCHAR(255),
    `data_source_url` TEXT,
    `created_by`      VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `category` (`category`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `pr_com_subcategories`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `subcategory`	  VARCHAR(255),
    `data_source_url` TEXT,
    `created_by`      VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `subcategory` (`subcategory`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `pr_com_categories_article_links`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `article_link`	        VARCHAR(255),
    `pr_com_category_id`    BIGINT,
    `data_source_url`       TEXT,
    `created_by`            VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `article_category_link` (`article_link`, `pr_com_category_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `pr_com_subcategories_article_links`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `article_link`	        VARCHAR(255),
    `pr_com_subcategory_id` BIGINT,
    `data_source_url`       TEXT,
    `created_by`            VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `article_subcategory_link` (`article_link`, `pr_com_subcategory_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;