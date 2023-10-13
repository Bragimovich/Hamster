create table usa_raw.irs_nonprofit_orgs
(
	id bigint auto_increment
		primary key,
	ein varchar(15) null,
	org_name varchar(255) null,
	org_name_parens varchar(255) null,
	org_name_aliases varchar(1000) null,
	state varchar(20) null,
	city varchar(100) null,
	scrape_dev_name varchar(7) default 'Oleh B.' null,
	data_source_url varchar(1000) null,
	created_at timestamp default CURRENT_TIMESTAMP not null,
	updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
	run_id int not null,
	touched_run_id int not null,
	deleted tinyint(1) default '0' null,
	md5_hash varchar(32) not null,
	constraint md5
		unique (md5_hash)
)
collate=utf8mb4_unicode_520_ci
comment 'Creator:Oleh B.';

create index ein
	on usa_raw.irs_nonprofit_orgs (ein);

create index deleted
	on usa_raw.irs_nonprofit_orgs (deleted);

create index run_id
	on usa_raw.irs_nonprofit_orgs (run_id);

create index touched_run_id
	on usa_raw.irs_nonprofit_orgs (touched_run_id);

