CREATE TABLE `ok_k12_employee_salaries`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                    BIGINT(20),
  `fiscal_year`               varchar(255),
  `teacher_number`            int,
  `staff_id`                  int,
  `county`                    int,
  `county_name`               VARCHAR(255),
  `district`                  int,
  `district_name`             VARCHAR(255),
  `site`                      VARCHAR(255),
  `school_name`               VARCHAR(255),
  `race`                      int,
  `race_desciption`           VARCHAR(255),
  `gender`                    VARCHAR(255),
  `degree`                    int,
  `degree_desciption`         VARCHAR(255),
  `job_code`                  int,
  `job_desciption`            VARCHAR(255),
  `subject`                   int,
  `subject_desciption`        VARCHAR(255),
  `fte`                       VARCHAR(255),
  `base_salary`               VARCHAR(255),
  `total_fringe`              VARCHAR(255),
  `other_fringe`              VARCHAR(255),
  `federal_base_salary`       VARCHAR(255),
  `federal_fte`               VARCHAR(255),
  `total_experience`         int,
  `district_paid_retirement` VARCHAR(255),
  `federal_fringe`           VARCHAR(255),
  `retired_employee`         VARCHAR(255),
  `state_flexible_benefits`  VARCHAR(255),
  `total_extra_duty`         VARCHAR(255),
  `total_other_salary`       VARCHAR(255),
  `last_name`                VARCHAR(255),
  `first_name`               VARCHAR(255),
  `ocas_program_code`        int,
  `reason_for_leaving_code`  int,
  `reason_for_leaving`       VARCHAR(255),
  `sort_order`               int,
  `email`                    VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Muhammad Musa',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Muhaamd Musa task # 777 ';