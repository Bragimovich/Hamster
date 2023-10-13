create table `raw_ky_jackson_county_inmates_arrests_from_1_1_2019_to_2_4_2023`
(
  `id`                  BIGINT(20) auto_increment   primary key,
  `arrest_id`           varchar(255),
  `agency`              varchar(255),
  `date_of_arrest`      date,
  `charge`              varchar(255),
  `name`                varchar(255),
  `sex`                 varchar(50),
  `race`                varchar(50),
  `page_no`             int,
  `full_row`            varchar(255),
  `charge_name`         varchar(255),
  `created_by`          VARCHAR(255)       DEFAULT 'Muhammad Qasim',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
