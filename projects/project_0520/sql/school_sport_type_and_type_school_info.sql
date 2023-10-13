create table ihsa_schools__sport_types__schools_info(
  id bigint auto_increment PRIMARY KEY,
  ihsa_school_sports_type_id int,
  ihsa_school_info_id int,
  data_source_url TEXT,
  created_by      VARCHAR(255)      DEFAULT 'Abdur Rehman',
  created_at      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id  BIGINT(20),
  touched_run_id  BIGINT,
  deleted         BOOLEAN           DEFAULT 0,
  md5_hash        VARCHAR(255),
  UNIQUE KEY md5 (md5_hash)
);