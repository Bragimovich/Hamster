create table inspector_general_reports_locations(
  id  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  report_id  bigint,
  location  text,
  city  varchar(255),
  state  varchar(255),
  country  varchar(255)  default 'US',
  md5_hash  VARCHAR(255)
)DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;