-- title — varchar
-- subtitle — varchar <optional>
-- teaser — text
-- article — longtext
-- link — varchar (unique key)
-- creator — varchar default 'Fannie Mae'
-- type — varchar (use downcase to fill this column) default ‘press release’
-- country — varchar default ‘US’
-- date — datetime

create table fannie_mae
(
  id                            BIGINT AUTO_INCREMENT PRIMARY KEY,
  run_id                        BIGINT,
  title                         VARCHAR(255),
  subtitle                      VARCHAR(255),
  teaser                        TEXT,
  article                       LONGTEXT,
  link                          VARCHAR(255),
  creator                       VARCHAR(255)       DEFAULT 'Fannie Mae',
  article_type                  VARCHAR(255)       DEFAULT 'press release',
  country                       VARCHAR(255)       DEFAULT 'US',
  date                          TIMESTAMP,

  data_source_url               VARCHAR(255),
  created_by                    VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  touched_run_id                BIGINT,
  deleted                       BOOLEAN            DEFAULT 0,
  md5_hash                      VARCHAR(255),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
