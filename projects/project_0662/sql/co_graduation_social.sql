create table `co_graduation_social`
(
  `id`                               int auto_increment   primary key,
  `run_id`                           int,
  `general_id`                       bigint  (20),
  `school_year`                      varchar (50),
  `group`                            varchar (255),
  `anticipated_year_of_graduation`   varchar (255),
  `year_after_entering_high_school`  varchar (255),
  `final_grad_base`                  varchar (255),
  `graduates_total`                  varchar (255),
  `graduation_rate`                  varchar (255),
  `completers_total`                 varchar (255),
  `completion_rate`                  varchar (255),
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
