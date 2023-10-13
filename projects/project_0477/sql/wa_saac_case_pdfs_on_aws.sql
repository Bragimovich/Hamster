create table wa_saac_case_pdfs_on_aws(
  id bigint(20) AUTO_INCREMENT primary key,
  court_id  int,
  case_id  varchar(200),
  source_type  varchar(200),
  aws_link  varchar(600),
  source_link  varchar(600),
  aws_html_link varchar(600),
  created_by  VARCHAR(255) default 'Abdur Rehman',
  created_at  DATETIME default CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  data_source_url TEXT,
  run_id  BIGINT,
  touched_run_id BIGINT(20), 
  deleted BOOLEAN  default 0,
  md5_hash  varchar(500),
  UNIQUE KEY aws_link (aws_link)
)default CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;