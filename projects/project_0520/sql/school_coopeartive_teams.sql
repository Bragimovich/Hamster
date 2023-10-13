create table ihsa_schools__cooperative_teams(
    id BIGINT(20) auto_increment primary key,
    host_school_id  int,
    opponent_school_id int,
    sport_id  int,
    coops_end VARCHAR(45),
    data_source_url TEXT,
    created_by      VARCHAR(255)      DEFAULT 'Abdur Rehman',
    created_at      DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id  BIGINT,
    touched_run_id  BIGINT,
    deleted         BOOLEAN           DEFAULT 0,
    md5_hash        VARCHAR(255),
    UNIQUE KEY md5 (md5_hash)
);