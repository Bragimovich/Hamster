create table `il_cccc_case_ids_temp`
(
  `id`                      int auto_increment primary key,
  `case_id`                 varchar(255)                                null,
  `created_by`              varchar(255)    default 'Abdul Wahab'       null,
  `created_at`              datetime        default CURRENT_TIMESTAMP   null
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
