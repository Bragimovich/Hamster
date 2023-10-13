use us_court_cases;
drop table ca_saac_case_runs;
CREATE TABLE ca_saac_case_runs
(
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(255) DEFAULT 'processing',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX status_idx (status)
)
    COMMENT = 'Script runs for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;