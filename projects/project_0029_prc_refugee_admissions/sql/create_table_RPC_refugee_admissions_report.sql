create table usa_raw.RPC_refugee_admissions_report
(
	id bigint auto_increment
		primary key,
	fiscal_year int null,
	month varchar(3) null,
  region varchar(150) null,
  country varchar(150) null,
  refugee_amount int null,
	scrape_dev_name varchar(7) default 'Oleh B.' null,
	scrape_frequency varchar(7) default 'Monthly' null,
	data_source_url varchar(50) default 'https://www.wrapsnet.org/admissions-and-arrivals/',
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

create index year_month_country
	on usa_raw.RPC_refugee_admissions_report (fiscal_year, month, coutry);

create index deleted
	on usa_raw.RPC_refugee_admissions_report (deleted);

create index run_id
	on usa_raw.RPC_refugee_admissions_report (run_id);

create index touched_run_id
	on usa_raw.RPC_refugee_admissions_report (touched_run_id);

