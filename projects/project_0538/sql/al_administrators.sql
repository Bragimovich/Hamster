CREATE TABLE al_administrators(
  `id`	              bigint(20)    AUTO_INCREMENT PRIMARY KEY,
  `general_id`	      bigint(20),
  `role`	          varchar(255),
  `full_name`	      varchar(255),
  `first_name`	      varchar(255),
  `last_name`	      varchar(255),
  `school_year`	      varchar(255),
  `data_source_url`   varchar(255),
  `created_by`        varchar(255)      DEFAULT 'Aglazkov',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP         DEFAULT CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`            BIGINT(20),
  `touched_run_id`    BIGINT,
  `deleted`           tinyint(1)           DEFAULT 0,
  `md5_hash`          VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;