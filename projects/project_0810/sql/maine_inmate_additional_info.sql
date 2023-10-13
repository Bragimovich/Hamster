CREATE TABLE IF NOT EXISTS `crime_inmate`.`maine_inmate_additional_info` (
  `id`                                BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `inmate_id`                         BIGINT(20)   NULL DEFAULT NULL,
  `height`                            VARCHAR(255) NULL DEFAULT NULL,
  `weight`                            VARCHAR(255) NULL DEFAULT NULL,
  `hair_color`                        VARCHAR(255) NULL DEFAULT NULL,
  `eye_color`                         VARCHAR(255) NULL DEFAULT NULL,
  `street_address`                    VARCHAR(255) NULL DEFAULT NULL,
  `age`                               INT(11)      NULL DEFAULT NULL,
  `age_as_of_date`                    INT(11)      NULL DEFAULT NULL,
  `visitation_status`                 VARCHAR(255) NULL DEFAULT NULL,
  `body_modification_raw`             VARCHAR(512) NULL DEFAULT NULL,
  `scars`                             VARCHAR(255) NULL DEFAULT NULL,
  `marks`                             VARCHAR(255) NULL DEFAULT NULL,
  `tattoos`                           VARCHAR(512) NULL DEFAULT NULL,
  `Other_Physical_Characteristics`    VARCHAR(255) NULL DEFAULT NULL,
  `Skin_Discolorations`               VARCHAR(255) NULL DEFAULT NULL,
  `current_location`                  VARCHAR(255) NULL DEFAULT NULL,
  `created_by`                        VARCHAR(255) NULL DEFAULT 'Afia',
  `created_at`                        DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                        DATETIME     NOT  NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                            BIGINT(20)   NULL DEFAULT NULL,
  `touched_run_id`                    BIGINT(20)   NULL DEFAULT NULL,
  `deleted`                           TINYINT(1)   NULL DEFAULT '0',
  `md5_hash`                          VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_immate_additional_info_immates1_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_immate_additional_info_immates810`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`maine_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Afia, Task #810';
