CREATE TABLE us_court_cases.ak_saac_case_relations_info_pdf
(
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    case_info_md5           VARCHAR(255)       NULL,
    case_pdf_on_aws_md5     VARCHAR(255)       NULL,
    created_by              VARCHAR(255)       DEFAULT 'ALim L.',
    created_at              DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;