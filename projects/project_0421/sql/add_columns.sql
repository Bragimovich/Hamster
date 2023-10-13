ALTER TABLE district_columbia__dcd_uscourts_gov ADD COLUMN md5_hash VARCHAR(32) DEFAULT NULL;
ALTER TABLE district_columbia__dcd_uscourts_gov ADD COLUMN run_id BIGINT(20) DEFAULT 1;
ALTER TABLE district_columbia__dcd_uscourts_gov ADD COLUMN touched_run_id BIGINT(20) DEFAULT 1;
ALTER TABLE district_columbia__dcd_uscourts_gov ADD COLUMN deleted TINYINT(1) DEFAULT 0;
