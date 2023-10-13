ALTER TABLE chicago_federation_musicians
ADD COLUMN run_id BIGINT(20),
ADD COLUMN touched_run_id BIGINT,
ADD COLUMN deleted BOOLEAN DEFAULT 0,
ADD COLUMN md5_hash VARCHAR(255),
ADD INDEX (run_id, touched_run_id, deleted),
ADD UNIQUE KEY (md5_hash);
