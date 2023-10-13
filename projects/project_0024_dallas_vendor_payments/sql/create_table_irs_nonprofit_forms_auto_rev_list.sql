create table usa_raw.irs_nonprofit_forms_auto_rev_list
(
  id bigint auto_increment
    primary key,
  created_at timestamp default CURRENT_TIMESTAMP not null,
  updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
  ein varchar(15) null,
  exemption_type_raw varchar(2) null,
  exemption_type_clean varchar(10) null,
  revocation_date varchar(10) null,
  revocation_posting_date varchar(10) null,
  exemption_reinstatement_date varchar(10) null,
  constraint ein_rev_post_date
    unique (ein, revocation_posting_date)
)
  collate=utf8mb4_unicode_520_ci
  comment 'Creator:Oleh B.';

create index ein
  on usa_raw.irs_nonprofit_forms_auto_rev_list (ein);

