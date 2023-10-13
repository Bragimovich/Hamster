create table usa_raw.irs_nonprofit_forms_990_series
(
  id bigint auto_increment
    primary key,
  created_at timestamp default CURRENT_TIMESTAMP not null,
  updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
  ein varchar(15) null,
  filing_type varchar(5) null,
  tax_period varchar(6) null,
  return_fill_date varchar(10) null,
  return_type varchar(10) null,
  return_pdf_link varchar(500) null,

  constraint ein_tax_period
    unique (ein, tax_period)
)
  collate=utf8mb4_unicode_520_ci
  comment 'Creator:Oleh B.';

create index ein
  on usa_raw.irs_nonprofit_forms_990_series (ein);

