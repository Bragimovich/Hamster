create table usa_raw.irs_nonprofit_forms_990n
(
  id bigint auto_increment
    primary key,
  created_at timestamp default CURRENT_TIMESTAMP not null,
  updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
  ein varchar(15) null,
  organization_terminated boolean not null default 0,
  tax_period varchar(6) null,
  tax_period_start varchar(10) null,
  tax_period_end varchar(10) null,
  principal_officer_name varchar(200) null,
  principal_officer_street varchar(200) null,
  principal_officer_city varchar(100) null,
  principal_officer_state varchar(30) null,
  principal_officer_zip varchar(15) null,
  mailing_address_street varchar(200) null,
  mailing_address_city varchar(100) null,
  mailing_address_state varchar(30) null,
  mailing_address_zip varchar(15) null,
  website_url varchar(300) null,

  constraint ein_tax_period
    unique (ein, tax_period)
)
  collate=utf8mb4_unicode_520_ci
  comment 'Creator:Oleh B.';

create index ein
  on usa_raw.irs_nonprofit_forms_990n (ein);

