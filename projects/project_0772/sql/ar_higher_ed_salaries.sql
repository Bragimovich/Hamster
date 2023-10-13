
create table `ar_higher_ed_salaries`
 (
  `id`                      int auto_increment  primary key,
  `fiscal_year`             varchar(15),
  `campus`                  varchar(255),
  `payee`                   varchar(255),
  `amount_paid`             decimal(20,2),
  `position_title`          varchar(255),
  `data_type`               varchar(31),
  `data_source_url`         varchar(511),
  `scrape_frequency`        varchar(25)         default 'monthly'     null,
  `created_by`              varchar(255)        default 'William D.'   null,
  `created_at`              datetime            default CURRENT_TIMESTAMP null,
  `updated_at`              TIMESTAMP           default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`                  bigint                                    null,
  `touched_run_id`          bigint                                    null,
  `deleted`                 tinyint(1)      default 0                 null,
  `md5_hash`                varchar(255)                              null,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;