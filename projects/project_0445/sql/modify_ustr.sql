use press_releases;
ALTER TABLE ustr
    ADD COLUMN run_id          BIGINT(20) AFTER updated_at,
    ADD COLUMN touched_run_id  BIGINT AFTER run_id,
    ADD COLUMN deleted         BOOLEAN DEFAULT 0 AFTER touched_run_id,
    ADD INDEX run_id (run_id),
    ADD INDEX touched_run_id (touched_run_id),
    ADD INDEX deleted (deleted);