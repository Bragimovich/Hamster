create table `federal_register_forecasted_notices`
(
  `id`                          BIGINT(20) auto_increment   primary key,
  `run_id`                      BIGINT(20) , 
  `title`                       varchar(255),
  `filed_at`                    DATETIME,
  `scheduled_publication_date`  DATETIME,
  `document_type`               varchar (255) ,
  `agency`                       varchar (255),
  `pages`                        varchar (255),
  `document_number`     varchar (255),
  `page_views`          varchar (255),
  `page_views_as_of`   DATETIME,
  `link`               varchar (255),
  `pdf_link`            varchar (255),
  `aws_pdf_link`        varchar (255),
  `pdf_appeared`        DATETIME,
  `data_source_url`     varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

     
