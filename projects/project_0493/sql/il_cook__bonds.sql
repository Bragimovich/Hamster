create table `il_cook__bonds`
(
  `id`                      int auto_increment   primary key,
  `arrest_id`               int,
  `hearing_id`              int,
  `charge_id`               varchar (255) DEFAULT null,
  `bond_category`           varchar (255) DEFAULT 'bond',
  `bond_number`             int,
  `bond_type`               varchar (255) DEFAULT NULL,
  `paid`                    varchar (255) DEFAULT NULL,
  `bond_amount`             int DEFAULT 1,
  `made_bond_release_date`  date DEFAULT NULL,
  `made_bond_release_time`  date DEFAULT NULL,
  `touched_run_id`          BIGINT(20),
  `run_id`                  int,
  `md5_hash`                varchar (255),
  `data_source_url`         varchar (255),
  `deleted`                 boolean          DEFAULT 0,
  `created_by`              VARCHAR(255)     DEFAULT 'Raza',
  `created_at`              DATETIME         DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #493';
