CREATE TABLE `us_dept_noaa_tags`(
`id` bigint(20) NOT NULL AUTO_INCREMENT  primary key,
`tag` varchar(255),
   UNIQUE KEY `unique_data` (`tag`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
