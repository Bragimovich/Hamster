use press_releases;
ALTER TABLE nsf
    MODIFY created_by varchar(20) NULL DEFAULT 'Pospelov Vyacheslav',
    ADD touched_run_id bigint(20) NULL AFTER run_id,
    ADD deleted tinyint(1) NULL DEFAULT 0  AFTER touched_run_id,
    ADD md5_hash varchar(32) NULL AFTER deleted;