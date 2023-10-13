  CREATE TABLE sc_higher_ed_salaries 
(
  id bigint(20) NOT NULL AUTO_INCREMENT,
  name VARCHAR(255),
  agency VARCHAR(255),
  job_title VARCHAR(255),
  total_compensation VARCHAR(255),
  bonuses VARCHAR(255),
  data_source_url VARCHAR(255),
  created_by varchar(255) DEFAULT 'Hassan',
  created_at datetime DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id bigint(20) DEFAULT NULL,
  touched_run_id bigint(20) DEFAULT NULL,
  deleted tinyint(1) DEFAULT '0',
  md5_hash varchar(150) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY `md5_hash` (md5_hash),
  KEY `run_id` (run_id),
  KEY `touched_run_id` (touched_run_id),
  KEY `deleted` (deleted)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
