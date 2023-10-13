CREATE TABLE fl_palmbeach_inmate_addresses
(
  id bigint(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20),
  `full_address` VARCHAR(255),
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
  INDEX `fl_palmbeach_address` (`inmate_id` ASC),
  CONSTRAINT `fl_palmbeach_address1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`fl_palmbeach_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
