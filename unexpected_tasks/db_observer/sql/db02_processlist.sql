CREATE TABLE `db02_processlists`
(
  `id`                BIGINT(20)         AUTO_INCREMENT PRIMARY KEY,
  # BEGIN tables checker
    `pid`             INT,
    `user`            VARCHAR(255),
    `host`            VARCHAR(255),
    `db`              VARCHAR(255),
    `command`         VARCHAR(255),
    `time`            INT,
    `state`           VARCHAR(255),
    `info`            MEDIUMTEXT,
  # END
  `data_source_url`   VARCHAR(255)       DEFAULT 'show full processlist',
  `created_by`        VARCHAR(255)       DEFAULT 'Oleksij Kuc',
  `created_at`        DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `pid` (`pid`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'processlist tracker, ...., Created by Oleksij Kuc';
