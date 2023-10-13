ALTER TABLE north_carolina_business_licenses_new_business_csv ADD COLUMN `touched` BIGINT NOT NULL DEFAULT 0;
ALTER TABLE north_carolina_business_licenses_new_business_csv ADD COLUMN `deleted` tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE north_carolina_business_licenses_new_business_csv ADD md5_hash VARCHAR(32) DEFAULT NULL;