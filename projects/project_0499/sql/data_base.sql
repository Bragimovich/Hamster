CREATE TABLE `il_chicago_arrests__csv`
(
  `id`                    BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  # BEGIN scrape 454
  `cb_no`                 INT(11),
  `case_number`           CHAR(8),
  `arrest_date`           DATETIME,
  `race`                  VARCHAR(50),
  `charge_1_statute`      VARCHAR(50),
  `charge_1_description`  VARCHAR(100),
  `charge_1_type`         CHAR(1),
  `charge_1_class`        CHAR(1),
  `charge_2_statute`      VARCHAR(50),
  `charge_2_description`  VARCHAR(100),
  `charge_2_type`         CHAR(1),
  `charge_2_class`        CHAR(1),
  `charge_3_statute`      VARCHAR(50),
  `charge_3_description`  VARCHAR(100),
  `charge_3_type`         CHAR(1),
  `charge_3_class`        CHAR(1),
  `charge_4_statute`      VARCHAR(50),
  `charge_4_description`  VARCHAR(100),
  `charge_4_type`         CHAR(1),
  `charge_4_class`        CHAR(1),
  `charges_statute`       VARCHAR(200),
  `charges_description`   VARCHAR(400),
  `charges_type`          VARCHAR(13),
  `charges_class`         VARCHAR(13),
  # END
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN                DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `il_chicago_arrests__runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

ALTER TABLE `il_chicago_arrests__csv`
DROP COLUMN `charges_statute`,
DROP COLUMN `charges_description`,
DROP COLUMN `charges_type`,
DROP COLUMN `charges_class`;
