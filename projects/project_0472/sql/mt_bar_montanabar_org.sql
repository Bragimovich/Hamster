create table `mt_bar_montanabar_org`
(
  `id`                        int auto_increment   primary key,
  `run_id`                    int,
  `md5_hash`                  varchar (255),
  `name`                      varchar (255),
  `date_admited`              date,
  `registration_status`       varchar (255),
  `type`                      varchar (255),
  `law_firm_address`          varchar (255),
  `law_firm_city`             varchar (255),
  `law_firm_state`            varchar (255),
  `scrape_frequency`          varchar (255) DEFAULT 'Weekly',
  `data_source_url`           varchar (255) DEFAULT "https://www.montanabar.org/cv5/cgi-bin/memberdll.dll/List?RANGE=1/10000&CUSTOMERTYPE=%3C%3EAPPLICANT&CUSTOMERTYPE=%3C%3ELAY_LAWSTU&CUSTOMERTYPE=%3C%3ELAY_MEMBER&CUSTOMERTYPE=%3C%3ELAY_SECT&PETNAMES=%3C%3EY",
  `deleted`                BOOLEAN    DEFAULT 0,
  `created_by`                varchar (255)   DEFAULT 'Tauseeq',    
  `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
  )DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  