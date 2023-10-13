create table `co_dropout_by_race`
(
  `id`                               int auto_increment   primary key,
  `run_id`                           int,
  `general_id`                       bigint  (20),
  `school_year`                      varchar (50),
  `grade`                            varchar (255),
  `race`                             varchar (255),
  `gender`                           varchar (255),
  `pupil_count`                      varchar (255),
  `dropouts`                         varchar (255),
  `dropout_rate`                     varchar (255),
  `deleted`                          BOOLEAN            DEFAULT 0,
  `touched_run_id`                   int,
  `md5_hash`                         VARCHAR(255)       DEFAULT NULL,
  `data_source_url`                  varchar (350),      
  `created_by`                       VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`                       DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id_index` (`run_id`),
  INDEX `general_id_index` (`general_id`),
  INDEX `school_year_index` (`school_year`),
  INDEX `deleted_index` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Tauseeq Tufail, Task #662';
