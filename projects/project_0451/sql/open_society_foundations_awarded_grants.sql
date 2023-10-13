CREATE TABLE `open_society_foundations`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `grant_id`          VARCHAR (255),
  `name`              VARCHAR (255),
  `year`              SMALLINT,
  `amount`            INT,
  `description`       VARCHAR (1500),
  `theme`             VARCHAR (255),
  `term`              VARCHAR (255),
  `funder`            VARCHAR (255),
  `referring_program` VARCHAR (255),
  `region`            VARCHAR (255),
  `data_source_url`   varchar(255)       DEFAULT "https://www.opensocietyfoundations.org/grants",
  `created_by`        VARCHAR(255)       DEFAULT "Abdur Rehman",
  `created_at`        DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`grant_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  