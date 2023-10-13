CREATE TABLE `wa_pierce_inmate_aliases` 
(
  `id`                BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id`         BIGINT(20) NULL DEFAULT NULL,
  `full_name`         VARCHAR(255) NULL DEFAULT NULL,
  `first_name`        VARCHAR(255) NULL DEFAULT NULL,
  `middle_name`       VARCHAR(255) NULL DEFAULT NULL,
  `last_name`         VARCHAR(255) NULL DEFAULT NULL,
  `suffix`            VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url`   TEXT NULL DEFAULT NULL,
  `created_by`        VARCHAR(255) NULL DEFAULT 'Raza',
  `created_at`        DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`            BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`    BIGINT(20) NULL DEFAULT NULL,
  `deleted`           TINYINT(1) NULL DEFAULT '0',
  `md5_hash`          VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY    (`id`),
  UNIQUE INDEX   `md5` (`md5_hash`) ,
  INDEX          `run_id` (`run_id`) ,
  INDEX          `touched_run_id` (`touched_run_id`) ,
  INDEX          `deleted` (`deleted`) ,
  INDEX          `fk_il_tazewell__arrestee_aliases_il_tazewell__arrestees1_idx` (`immate_id`) ,
  CONSTRAINT     `fk_il_tazewell__arrestee_aliases_il_tazewell__arrestees1`
  FOREIGN KEY    (`immate_id`)
  REFERENCES     `crime_inmate`.`missouri_inmates` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Raza Aslam, Task #0863';
