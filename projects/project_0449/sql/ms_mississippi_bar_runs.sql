use lawyer_status;
drop table ms_mississippi_bar_runs;
CREATE TABLE ms_mississippi_bar_runs
(
    id              BIGINT AUTO_INCREMENT   PRIMARY KEY,
    status          VARCHAR(255)                DEFAULT 'processing',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX `id` (`id`),
    INDEX status_idx (status)
)
    COMMENT = 'Script runs for Mississippi Bar(attorney data)'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;
