CREATE TABLE football__standings
(
  id                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  run_id                    BIGINT(20),
  home_team_id              BIGINT(20),
  home_conference_id        BIGINT(20),
  road_team_id              BIGINT(20),
  road_conference_id        BIGINT(20),
  game_date                 DATE,
  game_time                 VARCHAR(10),
  home_team_score           INT,
  road_team_score           INT,
  data_source_url           VARCHAR(255),
  created_by                VARCHAR(255)              DEFAULT 'Muhammad Qasim',
  created_at                DATETIME                  DEFAULT CURRENT_TIMESTAMP,
  updated_at                DATETIME NOT NULL         DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  touched_run_id            BIGINT,   
  deleted                   BOOLEAN                   DEFAULT 0,
  md5_hash                  VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted),
  KEY id (id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  