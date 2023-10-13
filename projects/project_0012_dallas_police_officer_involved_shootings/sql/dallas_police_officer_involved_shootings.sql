create table dallas_police_officer_involved_shootings
(
  id                         int auto_increment primary key,
  case_num                   varchar(20),
  date                       varchar(10),
  location                   varchar(255),
  incident_type              varchar(255),
  subject_weapon             varchar(255),
  subjects                   varchar(255),
  officers                   varchar(255),
  grand_jury_disposition     varchar(255),
  attorney_general_forms_url varchar(255),
  summary_url                varchar(255),
  geo_location               varchar(255),
  data_source_url            varchar(255)       default 'https://www.dallasopendata.com/Public-Safety/Dallas-Police-Officer-Involved-Shootings/4gmt-jyx2',
  created_by                 varchar(255)       default 'Art Jarocki',
  created_at                 timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
