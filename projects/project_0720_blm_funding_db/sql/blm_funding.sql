 
create table `blm_funding`
 (
  `id`                      int auto_increment  primary key,
  `contributor`             varchar(150)                              null,
  `recipient`               mediumtext                                null,
  `contributor_hq_location` varchar(20)                               null,
  `amount`                  varchar(150)                              null,
  `blm_movement`            varchar(150)                              null,
  `follow_through`          varchar(150)        default 'Unknown'     null,
  `details`                 mediumtext,
  `source`                  json                                      null,
  `gather_month`            smallint                                  null,
  `gather_year`             smallint                                  null,
  `scrape_frequency`        varchar(25)         default 'monthly'     null,
  `created_by`              varchar(255)        default 'Frank Rao'   null,
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

ALTER TABLE blm_funding CHANGE amount amount_ori varchar(150);
ALTER TABLE blm_funding ADD COLUMN `amount` bigint NULL AFTER `amount_ori`;
ALTER TABLE blm_funding MODIFY contributor_hq_location mediumtext;

