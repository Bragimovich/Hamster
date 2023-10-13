CREATE TABLE IF NOT EXISTS  illinois_sex_offenders_crimes(
  `id` bigint(20) NOT NULL AUTO_INCREMENT, 
  `sex_offender_id` int,
  `crime_code_id` int,
  PRIMARY KEY (`id`)
  );

ALTER TABLE illinois_sex_offenders_crimes ADD CONSTRAINT unique_record UNIQUE KEY(sex_offender_id,crime_code_id);
