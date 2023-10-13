CREATE TABLE `massachusetts_public_school_district_info`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `org_name`        VARCHAR(255),
  `org_id`          VARCHAR(255),
  `org_type`        VARCHAR(255),
  `contact_role`    VARCHAR(255),
  `contact_name`    VARCHAR(255),
  `address1`        VARCHAR(255),
  `address2`        VARCHAR(255),
  `city`            VARCHAR(255),
  `state`           VARCHAR(255),
  `zip`             VARCHAR(255),
  `phone`           VARCHAR(255),
  `fax`             VARCHAR(255),
  `grades`          VARCHAR(255),
  `data_source_url` VARCHAR(255) DEFAULT "https://profiles.doe.mass.edu/search/search.aspx?leftNavId=11238",
  `created_by`      VARCHAR(255)      DEFAULT 'Aqeel',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', org_name, org_id, org_type, contact_role,
    contact_name, address1, address2, city, state, zip, phone, fax, grades))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Aqeel';
