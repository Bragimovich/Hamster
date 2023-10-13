create table usa_raw.irs_nonprofit_forms_pub_78
(
  id bigint auto_increment
    primary key,
  created_at timestamp default CURRENT_TIMESTAMP not null,
  updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
  ein varchar(15) null,
  deductibility_code varchar(15) null,
  scrape_dev_name varchar(7) default 'Oleh B.' null,
  constraint ein_deductibility
  unique (ein, deductibility_code)
)
  collate=utf8mb4_unicode_520_ci
  comment 'Creator:Oleh B.';

create index ein
  on usa_raw.irs_nonprofit_forms_pub_78 (ein);

