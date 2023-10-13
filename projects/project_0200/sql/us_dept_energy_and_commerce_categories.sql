CREATE TABLE us_dept_energy_and_commerce_categories
(
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    category        VARCHAR(255),
    created_by      VARCHAR(255)       DEFAULT 'Abdur Rehman',
    created_at      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY category (category)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;