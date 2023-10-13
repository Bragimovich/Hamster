CREATE TABLE `il_prison_population_data_scrape_temp` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `data_source_url` varchar(255) DEFAULT NULL,
  `Idoc` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `sex` varchar(255) DEFAULT NULL,
  `race` varchar(255) DEFAULT NULL,
  `veteran_status` varchar(255) DEFAULT NULL,
  `current_admission_date` date DEFAULT NULL,
  `admission_type` varchar(255) DEFAULT NULL,
  `parent_institution` varchar(255) DEFAULT NULL,
  `projected_mandatory_supervised_release_date` date DEFAULT NULL,
  `projected_discharged_date` date DEFAULT NULL,
  `custody_date` date DEFAULT NULL,
  `sentenced_date` date DEFAULT NULL,
  `crime_class` varchar(255) DEFAULT NULL,
  `holding_offense` varchar(255) DEFAULT NULL,
  `sentence_years` varchar(255) DEFAULT NULL,
  `sentence_month` int(11) DEFAULT NULL,
  `truth_in_sentencing` varchar(255) DEFAULT NULL,
  `sentecning_county` varchar(255) DEFAULT NULL,
  `period` date DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `created_date` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `broken_date_of_birth` varchar(255) DEFAULT NULL,
  `broken_current_admission_date` varchar(255) DEFAULT NULL,
  `broken_projected_mandatory_supervised_release_date` varchar(255) DEFAULT NULL,
  `broken_projected_discharged_date` varchar(255) DEFAULT NULL,
  `broken_custody_date` varchar(255) DEFAULT NULL,
  `broken_sentenced_date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;