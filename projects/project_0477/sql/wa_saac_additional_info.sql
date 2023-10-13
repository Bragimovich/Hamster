create table wa_saac_additional_info(
  id bigint(20) AUTO_INCREMENT primary key,
  court_id int,
  case_id  varchar(100),
  lower_court_name  varchar(100),
  lower_case_id  varchar(100),
  lower_judge_name  text,
  lower_judgement_date  date,
  lower_link  varchar(600),
  disposition   varchar(600),
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