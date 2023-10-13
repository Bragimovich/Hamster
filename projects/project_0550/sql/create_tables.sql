
-- -----------------------------------------------------
-- Table `arrestees`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_arrestees` (
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY PRIMARY KEY,
  `full_name`         VARCHAR(255),
  `first_name`        VARCHAR(255),
  `middle_name`       VARCHAR(255),
  `last_name`         VARCHAR(255),
  `suffix`            VARCHAR(255),
  `birthdate`         DATE,
  `age`               INT,
  `race`              VARCHAR(45),
  `sex`               VARCHAR(45),
  `weight`            VARCHAR(45),
  `height`            VARCHAR(45),
  `eye_color`         VARCHAR(45),
  `hair_color`        VARCHAR(45),
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://www.meganslaw.ca.gov/Search.aspx#',
  
  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `states`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_states` (
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY PRIMARY KEY,
  `name`              VARCHAR(255),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `cities`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_cities` (
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY PRIMARY KEY,
  `name`              VARCHAR(1000),
  `states_id`         BIGINT(20),
  INDEX `fk_cities_states_idx` (`states_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Dictonary table';

-- -----------------------------------------------------
-- Table `zips`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_zips` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY PRIMARY KEY,
  `code`              VARCHAR(45),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `coordinates`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_coordinates` (
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `lat`               VARCHAR(45),
  `lon`               VARCHAR(45),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `addresses`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_addresses` (
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `full_address`      VARCHAR(1000),
  `cities_id`         BIGINT(20),
  `zips_id`           BIGINT(20),
  `states_id`         BIGINT(20),
  `coordinates_id`    BIGINT(20)        DEFAULT -1,
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://www.meganslaw.ca.gov/Search.aspx#',
  
  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `cities_idx` (`cities_id` ASC),
  INDEX `zips_idx` (`zips_id` ASC),
  INDEX `states_idx` (`states_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `coordinates_idx` (`coordinates_id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `arrestee_aliases`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_arrestee_aliases` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `arrestees_id`      BIGINT,
  `alias_full_name`   VARCHAR(255),
  `alias_first_name`  VARCHAR(255),
  `alias_middle_name` VARCHAR(255),
  `alias_last_name`   VARCHAR(255),
  `alias_suffix`      VARCHAR(255),
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://www.meganslaw.ca.gov/Search.aspx#',

  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `fk_arrestee_aliases_arrestees_idx` (`arrestees_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `mugshots`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_mugshots` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `arrestees_id`      BIGINT,
  `aws_link`          VARCHAR(255),
  `original_link`     VARCHAR(255),
  `date`              DATE,
  
  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `fk_mugshots_arrestees_idx` (`arrestees_id` ASC),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `arrestees_address`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_arrestees_address` (
  `addresses_id`      BIGINT(20),
  `arrestees_id`      BIGINT,
  INDEX `addresses_idx` (`addresses_id` ASC),
  INDEX `fk_arrestees_address_arrestees_idx` (`arrestees_id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `runs`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_runs` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `status`            VARCHAR(45) DEFAULT 'in progress',

  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `offense`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_offense` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `arrestees_id`       BIGINT,
  `offense_code`      VARCHAR(255),
  `last_conviction`   VARCHAR(45),
  `description`       VARCHAR(1000),
  `last_release`      VARCHAR(45),
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://www.meganslaw.ca.gov/Search.aspx#',

  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `fk_offense_arrestees_idx` (`arrestees_id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'extend arrests';

-- -----------------------------------------------------
-- Table `risk_assessment`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_risk_assessment` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `arrestees_id`       BIGINT,
  `score`             VARCHAR(255),
  `tool`              VARCHAR(45),
  `year`              INT,
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://www.meganslaw.ca.gov/Search.aspx#',

  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `fk_offense_arrestees_idx` (`arrestees_id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

-- -----------------------------------------------------
-- Table `marks`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `california_marks` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `arrestees_id`      BIGINT,
  `marks`             VARCHAR(45),
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://www.meganslaw.ca.gov/Search.aspx#',
  
  `run_id`            BIGINT,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(45),
  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  INDEX `fk_offense_arrestees1_idx` (`arrestees_id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;