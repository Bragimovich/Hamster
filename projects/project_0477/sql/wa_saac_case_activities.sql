create table wa_saac_case_activities(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  court_id varchar(200),
  case_id  varchar(200),
  activity_date DATE,
  activity_desc varchar(200),
  activity_type  varchar(500),
  file varchar(400),
  created_by  VARCHAR(255) default 'Abdur Rehman',
  created_at  DATETIME default CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  data_source_url TEXT,
  run_id  BIGINT,
  touched_run_id BIGINT(20),
  deleted BOOLEAN  default 0,
  md5_hash  VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  KEY id (id)
) default CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;