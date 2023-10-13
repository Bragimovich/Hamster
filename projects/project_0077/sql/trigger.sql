# CREATE TABLE `chicago_crime_statistics`
# (
#     `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
#     `run_id`          BIGINT(20),
#     # BEGIN scrape 77
#     `id_court`        BIGINT,
#     `case_number`     TEXT,
#     `date_court`      datetime,
#     `block`           TEXT,
#     `iucr`            text,
#     `primary_type`    text,
#     `description`     text,
#     `location_desc`   text,
#     `arrest`          text,
#     `domestic`        text,
#     `beat`            text,
#     `distrinct`       text,
#     `ward`            text,
#     `community_area`  text,
#     `fbi_code`        text,
#     `x_coordinate`    text,
#     `y_coordinate`    text,
#     `year`            int,
#     `update_on`       text,
#     `latitude`        text,
#     `longitude`       text,
#     `location`        text,
#     # END
#     `data_source_url` TEXT,
#     `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
#     `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
#     `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
#     `touched_run_id`  BIGINT,
#     `deleted`         BOOLEAN            DEFAULT 0,
#     `md5_hash`        VARCHAR(255),
#     UNIQUE KEY `md5` (`md5_hash`),
#     INDEX `run_id` (`run_id`),
#     INDEX `touched_run_id` (`touched_run_id`),
#     INDEX `deleted` (`deleted`)
# ) DEFAULT CHARSET = `utf8mb4`
#   COLLATE = utf8mb4_unicode_520_ci;

DROP TRIGGER uniq_deleted;

DELIMITER $$

CREATE TRIGGER uniq_deleted
    BEFORE INSERT
    ON chicago_crime_statistics
    FOR EACH ROW
BEGIN
    DECLARE var_flag boolean;

  SELECT COUNT(1) INTO var_flag FROM  chicago_crime_statistics AS t1
  WHERE t1.id_court = NEW.id_court AND  t1.deleted = 0;

     IF var_flag = 1 THEN

             UPDATE chicago_crime_statistics AS t1 SET touched_run_id = NEW.run_id
             WHERE t1.id_court = NEW.id_court AND deleted = 0 AND t1.md5_hash = NEW.md5_hash;
     END IF;
#             SIGNAL SQLSTATE '45000' ;
#         ELSE
#             UPDATE chicago_crime_statistics AS t1 SET touched_run_id = new.id_court, deleted = 1
#             WHERE t1.id_court = new.id_court AND deleted = 0;
#         END IF ;
#
END;
$$

DELIMITER ;

