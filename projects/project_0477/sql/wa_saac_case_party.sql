create table wa_saac_case_party(
  id bigint(20) AUTO_INCREMENT primary key,
  court_id  int,
  case_id  varchar(200),
  is_lawyer  varchar(200),
  party_name  varchar(600),
  party_type  varchar(600),
  party_law_firm  varchar(600),
  party_address  varchar(600),
  party_city  varchar(100),
  party_state  varchar(100),
  party_zip  varchar(600),
  party_description text,
  scrape_frequency  varchar(255)  default 'weekly',
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