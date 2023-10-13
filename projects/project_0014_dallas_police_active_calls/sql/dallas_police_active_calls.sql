CREATE TABLE dallas_police_active_calls_updates
(
  id              INT AUTO_INCREMENT PRIMARY KEY,
  incident_number VARCHAR(255),
  division        VARCHAR(255),
  nature_of_call  VARCHAR(255),
  priority        VARCHAR(255),
  date            VARCHAR(255),
  time            VARCHAR(255),
  unit_num        VARCHAR(255),
  block           VARCHAR(255),
  location        VARCHAR(255),
  beat            VARCHAR(255),
  reporting_area  VARCHAR(255),
  status          VARCHAR(255),
  done_at         VARCHAR(255),
  data_source_url VARCHAR(255)       DEFAULT 'https://www.dallasopendata.com/Public-Safety/Dallas-Police-Active-Calls/9fxf-t2tr',
  created_by      VARCHAR(255)       DEFAULT 'Art Jarocki',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  md5_hash        VARCHAR(255),
  UNIQUE KEY md5 (md5_hash)
);
