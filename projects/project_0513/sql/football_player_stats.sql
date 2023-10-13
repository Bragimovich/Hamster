CREATE TABLE `football__player_stats`
(
    `id`                 BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `saved_to_limpar`    BOOLEAN           DEFAULT 0,
    `team_id`            VARCHAR(255),
    `game_id`            VARCHAR(255),
    `player`             VARCHAR(255),
    `passing_cmp`        VARCHAR(255),
    `passing_att`        VARCHAR(255),
    `passing_yds`        VARCHAR(255),
    `passing_td`         VARCHAR(255),
    `passing_int`        VARCHAR(255),
    `passing_long`       VARCHAR(255),
    `passing_sack`       VARCHAR(255),
    `rushing_att`        VARCHAR(255),
    `rushing_gain`       VARCHAR(255),
    `rushing_loss`       VARCHAR(255),
    `rushing_net`        VARCHAR(255),
    `rushing_td`         VARCHAR(255),
    `rushing_lg`         VARCHAR(255),
    `rushing_avg`        VARCHAR(255),
    `receiving_rec`      VARCHAR(255),
    `receiving_yds`      VARCHAR(255),
    `receiving_td`       VARCHAR(255),
    `receiving_long`     VARCHAR(255),
    `defensive_solo`     VARCHAR(255),
    `defensive_ast`      VARCHAR(255),
    `defensive_tot`      VARCHAR(255),
    `defensive_tfl_yds`  VARCHAR(255),
    `defensive_sack_yds` VARCHAR(255),
    `defensive_ff`       VARCHAR(255),
    `defensive_f_r_yds`  VARCHAR(255),
    `defensive_int`      VARCHAR(255),
    `defensive_br_up`    VARCHAR(255),
    `defensive_blkd`     VARCHAR(255),
    `defensive_q_h`      VARCHAR(255),
    `data_source_url`    VARCHAR(255),
    `created_by`         VARCHAR(255)      DEFAULT 'Alim L.',
    `created_at`         DATETIME          DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id`             BIGINT(20),
    `touched_run_id`     BIGINT,
    `deleted`            BOOLEAN           DEFAULT 0,
    `md5_hash`           VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX                `run_id` (`run_id`),
    INDEX                `touched_run_id` (`touched_run_id`),
    INDEX                `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Alim L.';