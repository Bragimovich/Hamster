CREATE TABLE `il_school_suspensions`
(
    `id`                                 BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
    `academic_year`                      VARCHAR(9)   NOT NULL,

    `rcdts`                              VARCHAR(15)  DEFAULT NULL,
    `district_name`                      VARCHAR(155) NOT NULL,
    `school_name`                        VARCHAR(155) NOT NULL,

    `action_code`                        VARCHAR(2)   NOT NULL,
    `action_description`                 VARCHAR(155) NOT NULL,
    `total_incidents`                    INT          DEFAULT NULL,
    `total_students`                     INT          DEFAULT NULL,

    `female`                             INT          DEFAULT NULL,
    `male`                               INT          DEFAULT NULL,

    `hispanic_or_latino`                 INT          DEFAULT NULL,
    `american_indian_or_alaska_native`   INT          DEFAULT NULL,
    `black_or_african_american`          INT          DEFAULT NULL,
    `asian`                              INT          DEFAULT NULL,
    `native_hawaian_or_pacific_islander` INT          DEFAULT NULL,
    `white`                              INT          DEFAULT NULL,
    `two_or_more_races`                  INT          DEFAULT NULL,

    `grade_k_thru_8`                     INT          DEFAULT NULL,
    `grade_9_thru_12`                    INT          DEFAULT NULL,

    `EL`                                 INT          DEFAULT NULL,

    `alcohol`                            INT          DEFAULT NULL,
    `violence_with_physical_injury`      INT          DEFAULT NULL,
    `violence_without_physical_injury`   INT          DEFAULT NULL,
    `drug_offense`                       INT          DEFAULT NULL,
    `dangerous_weapon_firearm`           INT          DEFAULT NULL,
    `dangerous_weapon_other`             INT          DEFAULT NULL,
    `other_reason`                       INT          DEFAULT NULL,
    `tobacco`                            INT          DEFAULT NULL,

    `duration_1_day_or_less`             INT          DEFAULT NULL,
    `duration_1_1_to_2_9_days`           INT          DEFAULT NULL,
    `duration_3_0_to_4_9_days`           INT          DEFAULT NULL,
    `duration_5_0_to_10_days`            INT          DEFAULT NULL,
    `duration_greater_than_10_days`      INT          DEFAULT NULL,
    `duration_not_reported`              INT          DEFAULT NULL,

    `data_source_url`                    VARCHAR(255) DEFAULT 'https://www.isbe.net/Pages/Expulsions-Suspensions-and-Truants-by-District.aspx',
    `scrape_dev_name`                    VARCHAR(30)  DEFAULT 'Sergii Butrymenko',
    `scrape_frequency`                   VARCHAR(50)  DEFAULT 'annually',

    `created_at`                         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                         DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
