CREATE TABLE `fafsa_college_student_aid__by_state`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `name`            varchar(1000),            
  `city`            varchar(500),
  `state`           varchar(500),
  `school_code`     varchar(500),
  `applications_submitted`    varchar(255),
  `applications_submitted_on` varchar(255),
  `applications_complete`     varchar(255),
  `applications_completed_on` varchar(255), 
  `cycle`           varchar(255),          
  `through_date`   varchar(100),
  data_source_url TEXT,
  created_by      VARCHAR(255)      DEFAULT 'Abdur Rehman',
  created_at      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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