CREATE TABLE fl_palmbeach_holding_facilities
(
  id bigint(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20),
  `facility` VARCHAR(255),
  `facility_type` VARCHAR(255),
  `actual_release_date` DATE,
  data_source_url VARCHAR(255),
  created_by varchar(255) DEFAULT 'Hassan',
  created_at datetime DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id bigint(20) DEFAULT NULL,
  touched_run_id bigint(20) DEFAULT NULL,
  deleted tinyint(1) DEFAULT '0',
  md5_hash varchar(150) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (run_id),
  INDEX `touched_run_id` (touched_run_id),
  INDEX `deleted` (deleted),
  INDEX `fl_palmbeach_facility` (`arrest_id` ASC),
  CONSTRAINT `fl_palmbeach_facility1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`fl_palmbeach_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
