CREATE TABLE `us_nces_districts_raw`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`            BIGINT(20),
  `nces_district_id`  VARCHAR(255),
  `state_district_id` VARCHAR(255),
  `district_name`     VARCHAR(255),
  `county_name`       VARCHAR(255),
  `street_address`    VARCHAR(255),
  `city`              VARCHAR(255),
  `state`             VARCHAR(255),
  `zip`               VARCHAR(255),
  `zip_4_digit`       VARCHAR(255),
  `phone`             VARCHAR(255),
  `locale_code`       VARCHAR(255),
  `locale`            VARCHAR(255),
  `type`              VARCHAR(255),
  `data_source_url`   TEXT,
  `created_by`        VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'raw school districts table for task #752 US Schools NCES, made by Oleksii Kuts';

LOAD DATA LOCAL INFILE '/home/lexus/tmp/us_schools/districts.csv'
    INTO TABLE `us_nces_districts_raw`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18)
    SET run_id            = 1,
        nces_district_id  = @p1,
        state_district_id = @p2,
        district_name     = @p3,
        county_name       = @p4,
        street_address    = @p5,
        city              = @p6,
        state             = @p7,
        zip               = @p8,
        zip_4_digit       = @p9,
        phone             = @p10,
        locale_code       = @p14,
        locale            = @p15,
        type              = @p17,
        data_source_url   = 'https://nces.ed.gov/ccd/districtsearch/index.asp',
        touched_run_id    = 1,
        md5_hash          = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p14, @p15, @p17));

-- ===================================================================
CREATE TABLE `us_nces_districts_info_raw`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  `school_year`           VARCHAR(255),
  `nces_district_id`      VARCHAR(255),
  `students`              VARCHAR(255),
  `teachers`              VARCHAR(255),
  `schools`               VARCHAR(255),
  `student_teacher_ratio` VARCHAR(255),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'raw school districts` info table for task #752 US Schools NCES, made by Oleksii Kuts';

set @school_year = '2021-2022';

LOAD DATA LOCAL INFILE '/home/lexus/tmp/us_schools/districts.csv'
    INTO TABLE `us_nces_districts_info_raw`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18)
    SET run_id                = 1,
        school_year           = @school_year,
        nces_district_id      = @p1,
        students              = @p11,
        teachers              = @p12,
        schools               = @p13,
        student_teacher_ratio = @p16,
        data_source_url       = 'https://nces.ed.gov/ccd/districtsearch/index.asp',
        touched_run_id        = 1,
        md5_hash              = MD5(CONCAT_WS('', @school_year, @p1, @p11, @p12, @p13, @p16));

-- ===================================================================
CREATE TABLE `us_nces_schools_public_raw`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`            BIGINT(20),
  `nces_school_id`    VARCHAR(255),
  `state_school_id`   VARCHAR(255),
  `nces_district_id`  VARCHAR(255),
  `state_district_id` VARCHAR(255),
  `low_grade`         VARCHAR(255),
  `high_grade`        VARCHAR(255),
  `school_name`       VARCHAR(255),
  `district`          VARCHAR(255),
  `county_name`       VARCHAR(255),
  `street_address`    VARCHAR(255),
  `city`              VARCHAR(255),
  `state`             VARCHAR(255),
  `zip`               VARCHAR(255),
  `zip_4_digit`       VARCHAR(255),
  `phone`             VARCHAR(255),
  `locale_code`       VARCHAR(255),
  `locale`            VARCHAR(255),
  `data_source_url`   TEXT,
  `created_by`        VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'raw public schools table for task #752 US Schools NCES, made by Oleksii Kuts';

LOAD DATA LOCAL INFILE '/home/lexus/tmp/us_schools/public.csv'
    INTO TABLE `us_nces_schools_public_raw`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29)
    SET run_id            = 1,
        nces_school_id    = @p1,
        state_school_id   = @p2,
        nces_district_id  = @p3,
        state_district_id = @p4,
        low_grade         = @p5,
        high_grade        = @p6,
        school_name       = @p7,
        district          = @p8,
        county_name       = @p9,
        street_address    = @p10,
        city              = @p11,
        state             = @p12,
        zip               = @p13,
        zip_4_digit       = @p14,
        phone             = @p15,
        locale_code       = @p16,
        locale            = @p17,
        data_source_url   = 'https://nces.ed.gov/ccd/schoolsearch/index.asp',
        touched_run_id    = 1,
        md5_hash          = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17));

-- ===================================================================
CREATE TABLE `us_nces_schools_public_info_raw`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  `school_year`           VARCHAR(255),
  `nces_school_id`        VARCHAR(255),
  `charter`               VARCHAR(255),
  `magnet`                VARCHAR(255),
  `title_1_school`        VARCHAR(255),
  `title_1_school_wide`   VARCHAR(255),
  `students`              VARCHAR(255),
  `teachers`              VARCHAR(255),
  `student_teacher_ratio` VARCHAR(255),
  `free_lunch`            VARCHAR(255),
  `reduced_lunch`         VARCHAR(255),
  `directly_certified`    VARCHAR(255),
  `type`                  VARCHAR(255),
  `status`                VARCHAR(255),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'raw public schools` info table for task #752 US Schools NCES, made by Oleksii Kuts';

set @school_year = '2021-2022';

LOAD DATA LOCAL INFILE '/home/lexus/tmp/us_schools/public.csv'
    INTO TABLE `us_nces_schools_public_info_raw`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29)
    SET run_id                = 1,
        school_year           = @school_year,
        nces_school_id        = @p1,
        charter               = @p18,
        magnet                = @p19,
        title_1_school        = @p20,
        title_1_school_wide   = @p21,
        students              = @p22,
        teachers              = @p23,
        student_teacher_ratio = @p24,
        free_lunch            = @p25,
        reduced_lunch         = @p26,
        directly_certified    = @p27,
        type                  = @p28,
        status                = @p29,
        data_source_url       = 'https://nces.ed.gov/ccd/schoolsearch/index.asp',
        touched_run_id        = 1,
        md5_hash              = MD5(CONCAT_WS('', @school_year, @p1, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29));

-- ===================================================================
CREATE TABLE `us_nces_schools_private_raw`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `school_id`       VARCHAR(255),
  `school_name`     VARCHAR(255),
  `low_grade`       VARCHAR(255),
  `high_grade`      VARCHAR(255),
  `street_address`  VARCHAR(255),
  `city`            VARCHAR(255),
  `state`           VARCHAR(255),
  `zip`             VARCHAR(255),
  `phone`           VARCHAR(255),
  `county_no`       VARCHAR(255),
  `county_fips`     VARCHAR(255),
  `fips`            VARCHAR(255),
  `orient`          VARCHAR(255),
  `county_name`     VARCHAR(255),
  `locale_code`     VARCHAR(255),
  `type_code`       VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Oleksii Kuts',
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
    COMMENT = 'raw private schools table for task #752 US Schools NCES, made by Oleksii Kuts';

LOAD DATA LOCAL INFILE '/home/lexus/tmp/us_schools/private.csv'
    INTO TABLE `us_nces_schools_private_raw`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    ( @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10,
      @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20,
      @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30,
      @p31, @p32, @p33, @p34, @p35, @p36, @p37, @p38, @p39, @p40,
      @p41, @p42, @p43, @p44, @p45, @p46, @p47, @p48, @p49, @p50,
      @p51, @p52, @p53, @p54, @p55, @p56, @p57, @p58, @p59, @p60,
      @p61, @p62, @p63, @p64, @p65, @p66, @p67, @p68, @p69, @p70, @p71)
    SET run_id            = 1,
        school_id         = @p1,
        school_name       = @p2,
        low_grade         = @p3,
        high_grade        = @p4,
        street_address    = @p5,
        city              = @p6,
        state             = @p9,
        zip               = @p11,
        phone             = @p12,
        county_no         = @p7,
        county_fips       = @p8,
        fips              = @p10,
        orient            = @p55,
        county_name       = @p56,
        locale_code       = @p41,
        type_code         = @p43,
        data_source_url   = 'https://nces.ed.gov/surveys/pss/privateschoolsearch/',
        touched_run_id    = 1,
        md5_hash          = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p9, @p11, @p12, @p7, @p8, @p10, @p55, @p56, @p41, @p43));

-- ===================================================================
CREATE TABLE `us_nces_schools_private_info_raw`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `school_year`     varchar(255),
  `school_id`       varchar(255),
  `school_days`	    varchar(255),
  `day_hours`	      varchar(255),
  `library`     	  varchar(255),
  `enroll_ug`	      varchar(255),
  `enroll_pk`       varchar(255),
  `enroll_k`        varchar(255),
  `enroll_1`        varchar(255),
  `enroll_2`        varchar(255),
  `enroll_3`        varchar(255),
  `enroll_4`        varchar(255),
  `enroll_5`        varchar(255),
  `enroll_6`        varchar(255),
  `enroll_7`        varchar(255),
  `enroll_8`        varchar(255),
  `enroll_9`        varchar(255),
  `enroll_10`       varchar(255),
  `enroll_11`       varchar(255),
  `enroll_12`       varchar(255),
  `enroll_t`	      varchar(255),
  `enroll_tk_12`    varchar(255),
  `race_ai`	        varchar(255),
  `race_as`	        varchar(255),
  `race_h`          varchar(255),
  `race_b`          varchar(255),
  `race_w`          varchar(255),
  `race_p`          varchar(255),
  `race_2`          varchar(255),
  `fte_teach`	      varchar(255),
  `coed`            varchar(255),
  `level`	          varchar(255),
  `relig`	          varchar(255),
  `comm_type`	      varchar(255),
  `indian_pct`	    varchar(255),
  `asian_pct`	      varchar(255),
  `hisp_pct`	      varchar(255),
  `black_pct`	      varchar(255),
  `white_pct`	      varchar(255),
  `pacisl_pct`	    varchar(255),
  `twomore_pct`	    varchar(255),
  `stdtch_rt`	      varchar(255),
  `assoc_1`	        varchar(255),
  `assoc_2`         varchar(255),
  `assoc_3`         varchar(255),
  `assoc_4`         varchar(255),
  `assoc_5`         varchar(255),
  `assoc_6`         varchar(255),
  `assoc_7`         varchar(255),
  `assoc_8`         varchar(255),
  `assoc_9`         varchar(255),
  `assoc_10`        varchar(255),
  `assoc_11`        varchar(255),
  `assoc_12`        varchar(255),
  `assoc_13`        varchar(255),
  `assoc_14`        varchar(255),
  `assoc_15`        varchar(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Oleksii Kuts',
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
    COMMENT = 'raw private schools` info table for task #752 US Schools NCES, made by Oleksii Kuts';

set @school_year = '2019-2020';

LOAD DATA LOCAL INFILE '/home/lexus/tmp/us_schools/private.csv'
    INTO TABLE `us_nces_schools_private_info_raw`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    ( @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10,
      @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20,
      @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30,
      @p31, @p32, @p33, @p34, @p35, @p36, @p37, @p38, @p39, @p40,
      @p41, @p42, @p43, @p44, @p45, @p46, @p47, @p48, @p49, @p50,
      @p51, @p52, @p53, @p54, @p55, @p56, @p57, @p58, @p59, @p60,
      @p61, @p62, @p63, @p64, @p65, @p66, @p67, @p68, @p69, @p70, @p71)
    SET run_id          = 1,
        school_year     = @school_year,
        school_id       = @p1,
        school_days	    = @p13,
        day_hours	      = @p14,
        library     	  = @p15,
        enroll_ug	      = @p16,
        enroll_pk       = @p17,
        enroll_k        = @p18,
        enroll_1        = @p19,
        enroll_2        = @p20,
        enroll_3        = @p21,
        enroll_4        = @p22,
        enroll_5        = @p23,
        enroll_6        = @p24,
        enroll_7        = @p25,
        enroll_8        = @p26,
        enroll_9        = @p27,
        enroll_10       = @p28,
        enroll_11       = @p29,
        enroll_12       = @p30,
        enroll_t	      = @p31,
        enroll_tk_12    = @p32,
        race_ai	        = @p33,
        race_as	        = @p34,
        race_h          = @p35,
        race_b          = @p36,
        race_w          = @p37,
        race_p          = @p38,
        race_2          = @p39,
        fte_teach	      = @p40,
        coed            = @p42,
        level	          = @p44,
        relig	          = @p45,
        comm_type	      = @p46,
        indian_pct	    = @p47,
        asian_pct	      = @p48,
        hisp_pct	      = @p49,
        black_pct	      = @p50,
        white_pct	      = @p51,
        pacisl_pct	    = @p52,
        twomore_pct	    = @p53,
        stdtch_rt	      = @p54,
        assoc_1	        = @p57,
        assoc_2         = @p58,
        assoc_3         = @p59,
        assoc_4         = @p60,
        assoc_5         = @p61,
        assoc_6         = @p62,
        assoc_7         = @p63,
        assoc_8         = @p64,
        assoc_9         = @p65,
        assoc_10        = @p66,
        assoc_11        = @p67,
        assoc_12        = @p68,
        assoc_13        = @p69,
        assoc_14        = @p70,
        assoc_15        = @p71,
        data_source_url = 'https://nces.ed.gov/surveys/pss/privateschoolsearch/',
        touched_run_id  = 1,
        md5_hash        = MD5(CONCAT_WS('', @school_year, @p1,
                          @p13, @p14, @p15, @p16, @p17, @p18, @p19,
                          @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29,
                          @p30, @p31, @p32, @p33, @p34, @p35, @p36, @p37, @p38, @p39,
                          @p40, @p42, @p44, @p45, @p46, @p47, @p48, @p49,
                          @p50, @p51, @p52, @p53, @p54, @p57, @p58, @p59,
                          @p60, @p61, @p62, @p63, @p64, @p65, @p66, @p67, @p68, @p69,
                          @p70, @p71));

-- ===================================================================
