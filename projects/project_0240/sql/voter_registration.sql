CREATE TABLE IF NOT EXISTS kentucky_voter_registrations(
  id bigint(20) NOT NULL AUTO_INCREMENT, 
  run_id bigint(20),
  year varchar (255),
  month varchar (255),
  county varchar (255),
  precinct varchar (255),
  democratic varchar (255),
  republican varchar (255),
  other varchar (255),
  ind varchar (255),
  libert varchar (255),
  green varchar (255),
  const varchar (255),
  reform varchar (255),
  soc_wk varchar (255),
  male varchar (255),
  female varchar (255),
  registered varchar (255),
  scrape_dev_name VARCHAR(255) DEFAULT 'Aqeel',
  data_source_url VARCHAR(255),
  `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(concat_ws('',year,month,county,precinct,democratic,republican,other,ind,libert,green,const,reform,soc_wk,male,female,registered))) STORED unique key,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  scrape_frequency VARCHAR(255) DEFAULT 'Monthly',
  last_scrape_date date,
  next_scrape_date date,
  scrape_status VARCHAR(255) DEFAULT 'Live',
  dataset_name_prefix VARCHAR(255) DEFAULT 'kentucky_voter_registrations',
  expected_scrape_frequency VARCHAR(255) DEFAULT 'Monthly',
  pl_gather_task_id int DEFAULT 8723,
  PRIMARY KEY (id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
