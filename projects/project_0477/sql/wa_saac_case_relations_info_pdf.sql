create table wa_saac_case_relations_info_pdf(
  id bigint(20) AUTO_INCREMENT primary key,
  case_info_md5  varchar(200),
  case_pdf_on_aws_md5  varchar(200),
  created_by varchar(255) default 'Abdur Rehman',
  created_at datetime default CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  data_source_url TEXT,
  run_id  BIGINT,
  touched_run_id BIGINT(20),
  deleted BOOLEAN default 0,
  md5_hash  varchar(500),
  UNIQUE KEY md5 (md5_hash)
) default CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;