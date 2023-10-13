CREATE TABLE IF NOT EXISTS `us_dept_hssat_category`(
`id` bigint(20) NOT NULL AUTO_INCREMENT  primary key,
`category` varchar(255),
UNIQUE KEY `unique_data` (`category`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
