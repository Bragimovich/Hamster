CREATE TABLE us_dept_bureau_of_political_military_affairs_tags
(
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    tag        VARCHAR(255),
    created_by VARCHAR(255)       DEFAULT 'Eldar Mustafaiev',
    created_at DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY tag (tag)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;