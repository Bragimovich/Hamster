create table usa_raw.RPC_refugee_admissions_report_runs
(
	id bigint auto_increment
		primary key,
	status varchar(255) default 'processing' null,
	data_as_of varchar(10) null,
	created_at timestamp default CURRENT_TIMESTAMP not null,
	updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
)
collate=utf8mb4_unicode_520_ci
comment 'Creator:Oleh B.';

create index status_idx
	on usa_raw.RPC_refugee_admissions_report_runs (status);