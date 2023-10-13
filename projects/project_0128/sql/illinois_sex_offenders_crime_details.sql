CREATE TABLE IF NOT EXISTS illinois_sex_offenders_crime_details(
  id bigint(20) NOT NULL AUTO_INCREMENT, 
  crime_code varchar (255),
  crime_description varchar(255),
  PRIMARY KEY (id)
  );

ALTER TABLE illinois_sex_offenders_crime_details ADD CONSTRAINT unique_record UNIQUE KEY(crime_code);
