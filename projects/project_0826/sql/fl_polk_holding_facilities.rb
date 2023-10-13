-- crime_inmate.fl_polk_holding_facilities definition

CREATE TABLE `fl_polk_holding_facilities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` bigint(20) DEFAULT NULL,
  `facility` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `data_source_url` text DEFAULT NULL,
  `created_by` varchar(255) DEFAULT 'Hatri',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `run_id` bigint(20) DEFAULT NULL,
  `touched_run_id` bigint(20) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT 0,
  `md5_hash` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5` (`md5_hash`),
  KEY `run_id` (`run_id`),
  KEY `touched_run_id` (`touched_run_id`),
  KEY `deleted` (`deleted`),
  KEY `fk_fl_polk_holding_facilities` (`inmate_id`),
  CONSTRAINT `fk_fl_polk_holding_facilities` FOREIGN KEY (`inmate_id`) REFERENCES `fl_polk_inmates` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci COMMENT='Created by Hatri, Task #826';