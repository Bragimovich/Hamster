create table ct_assessment(
  `id`	bigint(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id`	bigint(20),
  `school_year`	varchar(50),
  `exam_name`	varchar(255),
  `grade`	varchar(255),
  `subject`	varchar(255),
  `demographic`	varchar(255),
  `number_of_students`	varchar(255),
  `number_tested`	varchar(255),
  `rate_percent`	varchar(255),
  `with_scored`	varchar(255),
  `average_score`	varchar(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Abur Rehman',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id          BIGINT(20),
  touched_run_id  BIGINT,
  deleted         BOOLEAN           DEFAULT 0,
  md5_hash        VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
