CREATE TABLE `GA_RAW_CONTRIBUTIONS`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  # BEGIN scrape 769
  `filer_id`              VARCHAR(255),
  `type`                  VARCHAR(255),
  `last_name`             VARCHAR(255),
  `first_name`            VARCHAR(255),
  `address`               VARCHAR(255),
  `city`                  VARCHAR(255),
  `state`                 VARCHAR(255),
  `zip`                   VARCHAR(255),
  `pac`                   VARCHAR(255),
  `occupation`            VARCHAR(255),
  `employer`              VARCHAR(255),
  `date`                  DATE,
  `election`              VARCHAR(255),
  `election_year`         INT,
  `cash_amount`           DECIMAL(10,2),
  `in_kind_amount`        DECIMAL(10,2),
  `in_kind_description`   VARCHAR(255),
  `candidate_first_name`  VARCHAR(255),
  `candidate_middle_name` VARCHAR(255),
  `candidate_last_name`   VARCHAR(255),
  `candidate_suffix`      VARCHAR(255),
  `committee_name`        VARCHAR(255),
  # END
  `data_source_url`       VARCHAR(255)        DEFAULT 'https://media.ethics.ga.gov/search/Campaign/Campaign_ByContributions.aspx',
  `created_by`            VARCHAR(255)        DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME            DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN             DEFAULT 0,
  `md5_hash`              VARCHAR(32),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'raw data from media.ethics.ga.gov, Created by Oleksii Kuts, Task #769';

# ================================================================================
SET @run_id = 1;

LOAD DATA LOCAL INFILE '~/tmp/GA_RAW/StateEthicsReport_2016.csv'
    INTO TABLE `GA_RAW_CONTRIBUTIONS`
    FIELDS TERMINATED BY '","' ESCAPED BY ''
    LINES TERMINATED BY '"\r\n'
    IGNORE 1 LINES
    (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22)
    SET run_id                = 1,
        filer_id              = NULLIF(SUBSTRING(@p1, 2), ''),
        type                  = NULLIF(@p2, ''),
        last_name             = NULLIF(@p3, ''),
        first_name            = NULLIF(@p4, ''),
        address               = NULLIF(@p5, ''),
        city                  = NULLIF(@p6, ''),
        state                 = NULLIF(@p7, ''),
        zip                   = NULLIF(@p8, ''),
        pac                   = NULLIF(@p9, ''),
        occupation            = NULLIF(@p10, ''),
        employer              = NULLIF(@p11, ''),
        date                  = STR_TO_DATE(@p12, '%m/%d/%Y %h:%i:%s %p'),
        election              = NULLIF(@p13, ''),
        election_year         = NULLIF(@p14, ''),
        cash_amount           = NULLIF(@p15, ''),
        in_kind_amount        = NULLIF(@p16, ''),
        in_kind_description   = NULLIF(@p17, ''),
        candidate_first_name  = NULLIF(@p18, ''),
        candidate_middle_name = NULLIF(@p19, ''),
        candidate_last_name   = NULLIF(@p20, ''),
        candidate_suffix      = NULLIF(@p21, ''),
        committee_name        = NULLIF(@p22, ''),
        touched_run_id        = 1,
        md5_hash              = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22));
