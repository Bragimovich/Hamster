CREATE TABLE `district_columbia__dcd_uscourts_gov`
(
  `id`                        INT           AUTO_INCREMENT PRIMARY KEY,
  `bar_number`	              VARCHAR(255)  DEFAULT NULL,
  `name`	                    VARCHAR(255)  DEFAULT NULL,
  `first_name`          	    VARCHAR(255)  DEFAULT NULL,
  `last_name`            	    VARCHAR(255)  DEFAULT NULL,
  `middle_name`   	          VARCHAR(255)  DEFAULT NULL,
  `date_admited`              DATE          DEFAULT NULL,
  `registration_status`       VARCHAR(255)  DEFAULT NULL,
  `sections`	                text          DEFAULT NULL,
  `type`	                    VARCHAR(255)  DEFAULT NULL,
  `phone`               	    VARCHAR(255)  DEFAULT NULL,
  `email`	                    VARCHAR(255)  DEFAULT NULL,
  `fax`	                      VARCHAR(255)  DEFAULT NULL,
  `law_firm_name`	            VARCHAR(255)  DEFAULT NULL,
  `law_firm_address`	        VARCHAR(255)  DEFAULT NULL,
  `law_firm_zip`	            VARCHAR(255)  DEFAULT NULL,
  `law_firm_city`             VARCHAR(255)  DEFAULT NULL,
  `law_firm_state`	          VARCHAR(255)  DEFAULT NULL,
  `law_firm_county`	          VARCHAR(255)  DEFAULT NULL,
  `name_prefix`	              VARCHAR(255)  DEFAULT NULL,
  `university`	              VARCHAR(255)  DEFAULT NULL,
  `professional_affiliation`  TEXT          DEFAULT NULL,
  `bio`	                      LONGTEXT      DEFAULT NULL,
  `website`	                  VARCHAR(255)  DEFAULT NULL,
  `linkedin`	                VARCHAR(255)  DEFAULT NULL,
  `facebook`	                VARCHAR(255)  DEFAULT NULL,
  `twitter`	                  VARCHAR(255)  DEFAULT NULL,
  `law_firm_website`	        VARCHAR(255)  DEFAULT NULL,
  `other_jurisdictions`	      TEXT          DEFAULT NULL,
  `judicial_district`	        VARCHAR(255)  DEFAULT NULL,
  `disciplinary_actions`	    TEXT          DEFAULT NULL,
  `private_practice`	        VARCHAR(255)  DEFAULT NULL,
  `insurance`	                VARCHAR(255)  DEFAULT NULL,
  `courts_of_admittance`	    VARCHAR(255)  DEFAULT NULL,
  `scrape_frequency`	        VARCHAR(255)  DEFAULT 'weekly',
  `data_source_url`           VARCHAR(255),
  `created_by`                VARCHAR(255)  DEFAULT 'Oleksii Kuts',
  `created_at`                DATETIME      DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `district_columbia__dcd_uscourts_gov__runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
